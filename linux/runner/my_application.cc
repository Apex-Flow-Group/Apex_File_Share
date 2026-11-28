#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include <fstream>
#include <sstream>
#include <string>
#include <ctime>

#include "flutter/generated_plugin_registrant.h"

// ─── Clipboard channel name (must match Dart side) ────────────────────────────
static const char kClipboardChannel[] = "com.apex.core/clipboard";

// ─── System colours channel (must match lib/platform/system_colors.dart) ─────
static const char kSystemColorsChannel[] = "com.apex.core/system_colors";

// The theme's colours by their standard GTK names, which every GTK theme
// defines and KDE fills from its own colour scheme.
static const char* const kSystemColorNames[] = {
    "theme_bg_color",          "theme_base_color",        "theme_fg_color",
    "theme_text_color",        "theme_selected_bg_color", "theme_selected_fg_color",
    "borders",                 "success_color",           "error_color",
    nullptr};

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;

  // Clipboard monitoring
  FlMethodChannel* clipboard_channel;
  gulong            clipboard_signal_id;
  GtkClipboard*     clipboard;

  // The system's colours, read from the window's theme.
  FlMethodChannel* colors_channel;
  GtkWidget*       window;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// ─── System colours ──────────────────────────────────────────────────────────
// Each colour as 0xAARRGGBB under its GTK name; a name the theme lacks is left out.
static FlValue* read_system_colors(GtkWidget* widget) {
  FlValue* map = fl_value_new_map();
  GtkStyleContext* ctx = gtk_widget_get_style_context(widget);
  for (int i = 0; kSystemColorNames[i] != nullptr; i++) {
    GdkRGBA c;
    if (!gtk_style_context_lookup_color(ctx, kSystemColorNames[i], &c)) {
      continue;
    }
    auto byte = [](double v) {
      return static_cast<int64_t>(CLAMP(v, 0.0, 1.0) * 255.0 + 0.5);
    };
    int64_t argb = (byte(c.alpha) << 24) | (byte(c.red) << 16) |
                   (byte(c.green) << 8) | byte(c.blue);
    fl_value_set_string_take(map, kSystemColorNames[i], fl_value_new_int(argb));
  }
  return map;
}

// The theme changed (the user picked other colours or another theme): the
// app takes the new ones at once.
static void on_style_updated(GtkWidget* widget, gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->colors_channel) return;
  g_autoptr(FlValue) colors = read_system_colors(widget);
  fl_method_channel_invoke_method(self->colors_channel, "changed", colors,
                                  nullptr, nullptr, nullptr);
}

// ─── Helper: temp file path ───────────────────────────────────────────────────
static std::string make_temp_path(const char* prefix, const char* ext) {
  const char* tmp = g_get_tmp_dir();
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  long tick = ts.tv_sec * 1000L + ts.tv_nsec / 1000000L;
  std::ostringstream oss;
  oss << tmp << "/" << prefix << tick << "." << ext;
  return oss.str();
}

// ─── GTK clipboard owner-change callback ─────────────────────────────────────
static void on_clipboard_changed(GtkClipboard* clipboard,
                                 GdkEvent* /*event*/,
                                 gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (!self->clipboard_channel) return;

  // ── Case 1: Files (text/uri-list) ────────────────────────────────────────
  GdkAtom uri_atom  = gdk_atom_intern_static_string("text/uri-list");
  GdkAtom png_atom  = gdk_atom_intern_static_string("image/png");

  if (gtk_clipboard_wait_is_target_available(clipboard, uri_atom)) {
    GtkSelectionData* sel =
        gtk_clipboard_wait_for_contents(clipboard, uri_atom);
    if (sel) {
      gchar** uris = gtk_selection_data_get_uris(sel);
      gtk_selection_data_free(sel);
      if (uris) {
        FlValue* paths_list = fl_value_new_list();
        for (int i = 0; uris[i] != nullptr; ++i) {
          gchar* path = g_filename_from_uri(uris[i], nullptr, nullptr);
          if (path) {
            fl_value_append_take(paths_list, fl_value_new_string(path));
            g_free(path);
          }
        }
        g_strfreev(uris);

        if (fl_value_get_length(paths_list) > 0) {
          g_autoptr(FlValue) args = fl_value_new_map();
          fl_value_set_string_take(args, "type", fl_value_new_string("files"));
          fl_value_set_string_take(args, "paths", paths_list);
          fl_method_channel_invoke_method(self->clipboard_channel,
                                         "onClipboardChanged", args,
                                         nullptr, nullptr, nullptr);
          return;
        }
        fl_value_unref(paths_list);
      }
    }
  }

  // ── Case 2: Image (image/png) ─────────────────────────────────────────────
  if (gtk_clipboard_wait_is_target_available(clipboard, png_atom)) {
    GtkSelectionData* sel =
        gtk_clipboard_wait_for_contents(clipboard, png_atom);
    if (sel) {
      const guchar* data = gtk_selection_data_get_data(sel);
      gint          len  = gtk_selection_data_get_length(sel);
      if (data && len > 0) {
        std::string path = make_temp_path("apex_clip_", "png");
        std::ofstream f(path, std::ios::binary);
        if (f.is_open()) {
          f.write(reinterpret_cast<const char*>(data), len);
          f.close();

          g_autoptr(FlValue) args = fl_value_new_map();
          fl_value_set_string_take(args, "type",
                                   fl_value_new_string("image"));
          g_autoptr(FlValue) paths_list = fl_value_new_list();
          fl_value_append_take(paths_list, fl_value_new_string(path.c_str()));
          fl_value_set_string(args, "paths", paths_list);
          fl_method_channel_invoke_method(self->clipboard_channel,
                                         "onClipboardChanged", args,
                                         nullptr, nullptr, nullptr);
          gtk_selection_data_free(sel);
          return;
        }
      }
      gtk_selection_data_free(sel);
    }
  }

  // ── Case 3: Plain text ────────────────────────────────────────────────────
  gchar* text = gtk_clipboard_wait_for_text(clipboard);
  if (text) {
    // Skip whitespace-only
    bool has_content = false;
    for (const char* p = text; *p; ++p) {
      if (*p != ' ' && *p != '\t' && *p != '\n' && *p != '\r') {
        has_content = true;
        break;
      }
    }
    if (has_content) {
      // The text stays in memory: it may be a password, and /tmp is
      // readable by other users of the machine.
      g_autoptr(FlValue) args = fl_value_new_map();
      fl_value_set_string_take(args, "type", fl_value_new_string("text"));
      fl_value_set_string_take(args, "text", fl_value_new_string(text));
      fl_method_channel_invoke_method(self->clipboard_channel,
                                     "onClipboardChanged", args,
                                     nullptr, nullptr, nullptr);
    }
    g_free(text);
  }
}

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // The window bar is the system's own, so the app looks like every other
  // window there (owner decision). GNOME's own apps draw a header bar, so on
  // GNOME the app draws one too. Everywhere else (KDE Plasma, tiling window
  // managers) the system draws its bar: the GNOME-style header bar looked
  // foreign on KDE, Wayland or X11 alike.
  gboolean use_header_bar = FALSE;
  const gchar* desktop = g_getenv("XDG_CURRENT_DESKTOP");
  if (desktop != nullptr) {
    g_auto(GStrv) names = g_strsplit(desktop, ":", -1);
    for (gchar** n = names; *n != nullptr; n++) {
      if (g_ascii_strcasecmp(*n, "GNOME") == 0) {
        use_header_bar = TRUE;
      }
    }
  }
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    use_header_bar = g_strcmp0(wm_name, "GNOME Shell") == 0;
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Apex Transfer");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Apex Transfer");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_window_set_icon_name(window, "apexsender");

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  // Flutter 3.50.1's Impeller on Linux (OpenGLESSDF) drew every gradient as
  // two flat colours with a hard edge on NVIDIA's open driver (nouveau) and
  // on software rendering (llvmpipe, as in a virtual machine); on Intel it
  // was smooth, and Skia is smooth on all three (measured 2026-11-28). The
  // app cannot know its users' drivers, so Skia it is. Try Impeller again on
  // a later Flutter.
  fl_dart_project_set_enable_impeller(project, FALSE);
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // ── Set up clipboard MethodChannel ────────────────────────────────────────
  FlEngine* engine = fl_view_get_engine(view);
  FlBinaryMessenger* messenger = fl_engine_get_binary_messenger(engine);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->clipboard_channel = fl_method_channel_new(
      messenger, kClipboardChannel, FL_METHOD_CODEC(codec));

  // Nothing is watched until Dart sends "start" (the user turned it on).
  self->clipboard = gtk_clipboard_get(GDK_SELECTION_CLIPBOARD);
  fl_method_channel_set_method_call_handler(
      self->clipboard_channel,
      [](FlMethodChannel*, FlMethodCall* call, gpointer user_data) {
        MyApplication* self = MY_APPLICATION(user_data);
        const gchar* method = fl_method_call_get_name(call);
        g_autoptr(FlMethodResponse) response = nullptr;
        if (g_strcmp0(method, "start") == 0) {
          if (self->clipboard_signal_id == 0) {
            self->clipboard_signal_id =
                g_signal_connect(self->clipboard, "owner-change",
                                 G_CALLBACK(on_clipboard_changed), self);
          }
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else if (g_strcmp0(method, "stop") == 0) {
          if (self->clipboard_signal_id > 0) {
            g_signal_handler_disconnect(self->clipboard,
                                        self->clipboard_signal_id);
            self->clipboard_signal_id = 0;
          }
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
        }
        fl_method_call_respond(call, response, nullptr);
      },
      self, nullptr);

  // ── Set up system colours MethodChannel ───────────────────────────────────
  self->window = GTK_WIDGET(window);
  self->colors_channel = fl_method_channel_new(
      messenger, kSystemColorsChannel, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->colors_channel,
      [](FlMethodChannel*, FlMethodCall* call, gpointer user_data) {
        MyApplication* self = MY_APPLICATION(user_data);
        g_autoptr(FlMethodResponse) response = nullptr;
        if (g_strcmp0(fl_method_call_get_name(call), "get") == 0) {
          g_autoptr(FlValue) colors = read_system_colors(self->window);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(colors));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
        }
        fl_method_call_respond(call, response, nullptr);
      },
      self, nullptr);
  g_signal_connect(window, "style-updated", G_CALLBACK(on_style_updated), self);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // Disconnect clipboard signal and release channel
  if (self->clipboard && self->clipboard_signal_id > 0) {
    g_signal_handler_disconnect(self->clipboard, self->clipboard_signal_id);
    self->clipboard_signal_id = 0;
    self->clipboard = nullptr;
  }
  g_clear_object(&self->clipboard_channel);
  g_clear_object(&self->colors_channel);
  self->window = nullptr;

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->clipboard_channel    = nullptr;
  self->clipboard_signal_id  = 0;
  self->clipboard            = nullptr;
  self->colors_channel       = nullptr;
  self->window               = nullptr;
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
