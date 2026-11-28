#!/bin/bash
# ============================================================
#  Apex File Share — Build Tool
# ============================================================

KEYSTORE_DIR="$HOME/.apex_keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/apex_release.jks"
KEY_PROPERTIES="android/key.properties"
OUTPUT_DIR="releases"
APP_NAME="ApexFileShare"

# ── ألوان ────────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' W='\033[1;37m' N='\033[0m'

# ── إصدار ────────────────────────────────────────────────────
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
VERSION_NAME="${VERSION%+*}"
VERSION_CODE="${VERSION#*+}"

# ── تحقق من الـ Keystore ─────────────────────────────────────
ensure_keystore() {
    if [ -f "$KEYSTORE_FILE" ] && [ -f "$KEY_PROPERTIES" ]; then
        echo -e "${G}✅ Keystore موجود ومحفوظ${N}"
        return 0
    fi

    echo -e "${Y}🔑 إعداد Keystore (مرة واحدة فقط)...${N}"
    mkdir -p "$KEYSTORE_DIR"

    if [ ! -f "$KEYSTORE_FILE" ]; then
        read -s -p "  كلمة مرور الـ Keystore: " KS_PASS; echo
        read -s -p "  تأكيد كلمة المرور:      " KS_PASS2; echo
        if [ "$KS_PASS" != "$KS_PASS2" ]; then
            echo -e "${R}❌ كلمتا المرور غير متطابقتان${N}"; exit 1
        fi
        KEY_PASS="$KS_PASS"

        keytool -genkeypair -v \
            -keystore "$KEYSTORE_FILE" \
            -alias apex_key \
            -keyalg RSA -keysize 2048 \
            -validity 10000 \
            -storepass "$KS_PASS" \
            -keypass "$KEY_PASS" \
            -dname "CN=Apex-File-Share, O=Apex-Flow, C=SA" 2>/dev/null

        echo -e "${G}✅ تم إنشاء Keystore في: $KEYSTORE_FILE${N}"
    else
        read -s -p "  أدخل كلمة مرور الـ Keystore الموجود: " KS_PASS; echo
        KEY_PASS="$KS_PASS"
    fi

    cat > "$KEY_PROPERTIES" <<EOF
storePassword=$KS_PASS
keyPassword=$KEY_PASS
keyAlias=apex_key
storeFile=$KEYSTORE_FILE
EOF
    echo -e "${G}✅ تم حفظ key.properties${N}"
}

# ── دوال العمليات ─────────────────────────────────────────────
do_clean() {
    echo -e "${C}🧹 تنظيف...${N}"
    flutter clean
    echo -e "${G}✅ تم التنظيف${N}"
}

do_pub_get() {
    echo -e "${C}📦 تحديث الحزم...${N}"
    flutter pub get
    echo -e "${G}✅ تم تحديث الحزم${N}"
}

do_build_apk() {
    ensure_keystore
    echo -e "${C}🔨 بناء APK...${N}"
    flutter build apk --release --obfuscate --split-debug-info=build/debug_info
    RELEASE_FOLDER="$OUTPUT_DIR/v$VERSION_NAME"
    mkdir -p "$RELEASE_FOLDER"
    APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
    APK_DEST="$RELEASE_FOLDER/${APP_NAME}-v${VERSION_NAME}.apk"
    cp "$APK_SRC" "$APK_DEST"
    echo -e "${G}✅ APK: $APK_DEST ($(du -sh "$APK_DEST" | cut -f1))${N}"
}

do_build_aab() {
    ensure_keystore
    echo -e "${C}🔨 بناء AAB...${N}"
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info
    RELEASE_FOLDER="$OUTPUT_DIR/v$VERSION_NAME"
    mkdir -p "$RELEASE_FOLDER"
    AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
    AAB_DEST="$RELEASE_FOLDER/${APP_NAME}-v${VERSION_NAME}.aab"
    cp "$AAB_SRC" "$AAB_DEST"
    echo -e "${G}✅ AAB: $AAB_DEST ($(du -sh "$AAB_DEST" | cut -f1))${N}"
}

do_build_all() {
    ensure_keystore
    echo -e "${C}🔨 بناء APK + AAB...${N}"
    flutter build apk --release --obfuscate --split-debug-info=build/debug_info
    flutter build appbundle --release --obfuscate --split-debug-info=build/debug_info
    RELEASE_FOLDER="$OUTPUT_DIR/v$VERSION_NAME"
    mkdir -p "$RELEASE_FOLDER"
    APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
    AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
    APK_DEST="$RELEASE_FOLDER/${APP_NAME}-v${VERSION_NAME}.apk"
    AAB_DEST="$RELEASE_FOLDER/${APP_NAME}-v${VERSION_NAME}.aab"
    ZIP_DEST="$RELEASE_FOLDER/${APP_NAME}-v${VERSION_NAME}-release.zip"
    cp "$APK_SRC" "$APK_DEST"
    cp "$AAB_SRC" "$AAB_DEST"
    zip -j "$ZIP_DEST" "$APK_DEST" "$AAB_DEST" > /dev/null
    sha256sum "$APK_DEST" "$AAB_DEST" > "$RELEASE_FOLDER/checksums.sha256"
    echo -e "${G}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                  ✅ اكتمل البناء                     ║"
    echo "╠══════════════════════════════════════════════════════╣"
    printf "║  الإصدار : %-43s║\n" "v$VERSION_NAME (code: $VERSION_CODE)"
    printf "║  APK     : %-43s║\n" "$(du -sh "$APK_DEST" | cut -f1) — ${APK_DEST##*/}"
    printf "║  AAB     : %-43s║\n" "$(du -sh "$AAB_DEST" | cut -f1) — ${AAB_DEST##*/}"
    printf "║  ZIP     : %-43s║\n" "$(du -sh "$ZIP_DEST" | cut -f1) — ${ZIP_DEST##*/}"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${N}"
}

do_install() {
    DEVICES=$(adb devices | grep -v "List" | grep "device$" | awk '{print $1}')
    COUNT=$(echo "$DEVICES" | grep -c . 2>/dev/null || echo 0)
    if [ "$COUNT" -eq 0 ]; then
        echo -e "${R}❌ لا يوجد جهاز متصل${N}"; return
    fi
    APK="build/app/outputs/flutter-apk/app-release.apk"
    [ ! -f "$APK" ] && APK="$OUTPUT_DIR/v$VERSION_NAME/${APP_NAME}-v${VERSION_NAME}.apk"
    if [ ! -f "$APK" ]; then
        echo -e "${Y}⚠️  لا يوجد APK، سيتم البناء أولاً...${N}"
        do_build_apk
    fi
    echo -e "${C}📲 تثبيت على الجهاز...${N}"
    adb install -r "$APK"
    echo -e "${G}✅ تم التثبيت${N}"
}

do_uninstall() {
    PACKAGE=$(grep 'applicationId' android/app/build.gradle | awk -F'"' '{print $2}' | head -1)
    [ -z "$PACKAGE" ] && PACKAGE=$(grep 'applicationId' android/app/build.gradle.kts | awk -F'"' '{print $2}' | head -1)
    echo -e "${C}🗑️  إزالة $PACKAGE...${N}"
    adb uninstall "$PACKAGE" && echo -e "${G}✅ تم الإزالة${N}" || echo -e "${R}❌ فشل الإزالة${N}"
}

do_run() {
    echo -e "${C}▶️  تشغيل في وضع debug...${N}"
    flutter run
}

do_logs() {
    echo -e "${C}📋 سجلات التطبيق (Ctrl+C للإيقاف)...${N}"
    PACKAGE=$(grep 'applicationId' android/app/build.gradle | awk -F'"' '{print $2}' | head -1)
    adb logcat --pid="$(adb shell pidof -s "$PACKAGE")" 2>/dev/null || adb logcat | grep -i "flutter\|apex"
}

do_reset_keystore() {
    echo -e "${R}⚠️  هذا سيحذف الـ Keystore الحالي!${N}"
    read -p "  هل أنت متأكد؟ (yes/no): " CONFIRM
    if [ "$CONFIRM" = "yes" ]; then
        rm -f "$KEYSTORE_FILE" "$KEY_PROPERTIES"
        echo -e "${G}✅ تم الحذف — سيتم إنشاء keystore جديد عند البناء${N}"
    else
        echo -e "${Y}إلغاء${N}"
    fi
}

# Windows (Git Bash) only: the steps of build_windows.bat, then a silent
# install, checked against the build.
do_build_windows() {
    case "$(uname -s)" in
        MINGW*|MSYS*|CYGWIN*) ;;
        *) echo -e "${R}❌ مثبّت Windows يُبنى على Windows فقط، من Git Bash${N}"; return 1 ;;
    esac
    if ! flutter analyze lib/ --no-pub | tee /dev/stderr | grep -q "No issues found"; then
        echo -e "${R}❌ وجد flutter analyze ملاحظات، فلم يُبنَ شيء. أصلحها أولاً${N}"
        return 1
    fi
    flutter build windows --release || return 1
    local exe="build/windows/x64/runner/Release/file_share_app.exe"
    [ -f "$exe" ] || { echo -e "${R}❌ لم يُبنَ file_share_app.exe${N}"; return 1; }
    local iscc="${ISCC:-/c/Program Files (x86)/Inno Setup 6/ISCC.exe}"
    if [ ! -f "$iscc" ]; then
        echo -e "${R}❌ لم يُعثر على Inno Setup 6 في $iscc. ثبّته من https://jrsoftware.org/isdl.php أو ضع مساره في ISCC${N}"
        return 1
    fi
    "$iscc" windows/apex_file_share_setup.iss >/dev/null || { echo -e "${R}❌ فشل بناء المثبّت${N}"; return 1; }
    local setup="installer/ApexFileShare_Setup_${VERSION_NAME}.${VERSION_CODE}.exe"
    [ -f "$setup" ] || { echo -e "${R}❌ لم يُعثر على $setup${N}"; return 1; }
    echo -e "${G}✅ المثبّت: $setup ($(du -h "$setup" | cut -f1))${N}"
    MSYS2_ARG_CONV_EXCL='*' "$setup" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS || {
        echo -e "${R}❌ فشل التثبيت الصامت${N}"; return 1; }
    local installed="$LOCALAPPDATA/Programs/Apex File Share/data/app.so"
    if cmp -s "$installed" "build/windows/x64/runner/Release/data/app.so"; then
        echo -e "${G}✅ ثُبّت $VERSION_NAME+$VERSION_CODE، والكود المثبّت مطابق للبناء${N}"
    else
        echo -e "${R}❌ app.so في $installed غير موجود أو لا يطابق البناء. إن كان التطبيق مفتوحاً فأغلقه وأعد المحاولة${N}"
        return 1
    fi
}

# Fedora only: builds the package with packaging/fedora/build_rpm.sh at the
# pubspec version, then installs it (reinstalls the same version too).
do_build_rpm() {
    if [ ! -f /etc/fedora-release ] || ! command -v rpmbuild >/dev/null; then
        echo -e "${R}❌ حزمة RPM تُبنى على Fedora فقط، وتحتاج rpmbuild (sudo dnf install rpm-build)${N}"
        return 1
    fi
    bash packaging/fedora/build_rpm.sh "$VERSION_NAME" "$VERSION_CODE" || return 1
    RPM=$(ls build/rpm/apexsender-"$VERSION_NAME"-"$VERSION_CODE".*.rpm 2>/dev/null | head -1)
    if [ -z "$RPM" ]; then
        echo -e "${R}❌ لم يُعثر على الحزمة في build/rpm${N}"
        return 1
    fi
    if rpm -q apexsender >/dev/null 2>&1; then
        sudo dnf reinstall -y "$RPM" || sudo dnf install -y "$RPM"
    else
        sudo dnf install -y "$RPM"
    fi
    # dnf refuses a version older than the installed one without failing here.
    INSTALLED=$(rpm -q --qf '%{VERSION}-%{RELEASE}' apexsender 2>/dev/null) || INSTALLED=""
    case "$INSTALLED" in
        "$VERSION_NAME-$VERSION_CODE"|"$VERSION_NAME-$VERSION_CODE".*)
            echo -e "${G}✅ المثبّت الآن: apexsender $INSTALLED${N}" ;;
        *)
            echo -e "${R}❌ لم يُثبَّت $VERSION_NAME-$VERSION_CODE (رقم pubspec)، والمثبّت الآن: ${INSTALLED:-لا شيء}. dnf لا يثبّت إصداراً أقدم من المثبّت، فارفع رقم البناء أو أزل الحزمة أولاً.${N}"
            return 1 ;;
    esac
}

# ── القائمة الرئيسية ──────────────────────────────────────────
show_menu() {
    clear
    echo -e "${W}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║      Apex File Share Build Tool       ║"
    printf "  ║      v%-33s║\n" "$VERSION_NAME (code: $VERSION_CODE)"
    echo "  ╠═══════════════════════════════════════╣"
    echo "  ║                                       ║"
    echo -e "  ║  ${C}[1]${W} Clean                            ║"
    echo -e "  ║  ${C}[2]${W} Pub Get                          ║"
    echo -e "  ║  ${C}[3]${W} Clean + Pub Get                  ║"
    echo "  ║  ─────────────────────────────────── ║"
    echo -e "  ║  ${G}[4]${W} Build APK                        ║"
    echo -e "  ║  ${G}[5]${W} Build AAB                        ║"
    echo -e "  ║  ${G}[6]${W} Build APK + AAB + ZIP            ║"
    echo -e "  ║  ${G}[R]${W} Build RPM + Install (Fedora)     ║"
    echo -e "  ║  ${G}[W]${W} Build EXE + Install (Windows)    ║"
    echo "  ║  ─────────────────────────────────── ║"
    echo -e "  ║  ${Y}[7]${W} Install APK على الجهاز           ║"
    echo -e "  ║  ${Y}[8]${W} Uninstall من الجهاز              ║"
    echo -e "  ║  ${Y}[9]${W} Run (debug)                      ║"
    echo -e "  ║  ${Y}[L]${W} Logs                             ║"
    echo "  ║  ─────────────────────────────────── ║"
    echo -e "  ║  ${R}[K]${W} إعادة إنشاء Keystore             ║"
    echo -e "  ║  ${R}[Q]${W} خروج                             ║"
    echo "  ║                                       ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${N}"

    # حالة الـ Keystore
    if [ -f "$KEYSTORE_FILE" ]; then
        echo -e "  ${G}🔑 Keystore: موجود ومحفوظ${N}"
    else
        echo -e "  ${R}🔑 Keystore: غير موجود (سيُنشأ عند البناء)${N}"
    fi
    echo ""
    read -p "  اختر: " CHOICE
}

# ── الحلقة الرئيسية ───────────────────────────────────────────
while true; do
    show_menu
    case "${CHOICE,,}" in
        1) do_clean ;;
        2) do_pub_get ;;
        3) do_clean && do_pub_get ;;
        4) do_build_apk ;;
        5) do_build_aab ;;
        6) do_build_all ;;
        r) do_build_rpm ;;
        w) do_build_windows ;;
        7) do_install ;;
        8) do_uninstall ;;
        9) do_run ;;
        l) do_logs ;;
        k) do_reset_keystore ;;
        q) echo -e "${G}👋 وداعاً!${N}"; exit 0 ;;
        *) echo -e "${R}❌ اختيار غير صحيح${N}" ;;
    esac
    echo ""
    read -p "  اضغط Enter للعودة للقائمة..."
done
