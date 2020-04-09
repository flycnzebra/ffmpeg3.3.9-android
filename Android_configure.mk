# FFmpeg for Android
# http://sourceforge.net/projects/ffmpeg4android/
# Srdjan Obucina <obucinac@gmail.com>

LOCAL_PATH:=$(call my-dir)

include $(CLEAR_VARS)

# Use $(ANDROID_TOOLCHAIN) for library configuration
NDK_CROSS_PREFIX := $(subst -gcc,-,$(shell (ls $(ANDROID_TOOLCHAIN)/*gcc)))

# Always select highest NDK and SDK version
NDK_SYSROOT := $(ANDROID_BUILD_TOP)/$(shell (ls -dv prebuil*/ndk/android-ndk-r*/platforms/android-*/arch-$(TARGET_ARCH) | tail -1))

# Fix for latest master branch
ifeq ($(NDK_SYSROOT),$(ANDROID_BUILD_TOP)/)
    NDK_SYSROOT := $(ANDROID_BUILD_TOP)/$(shell (ls -dv prebuil*/ndk/current/platforms/android-*/arch-$(TARGET_ARCH) | tail -1))
endif

FF_CONFIGURATION_STRING := \
    --arch=$(TARGET_ARCH) \
    --target-os=linux \
    --enable-cross-compile \
    --cross-prefix=$(NDK_CROSS_PREFIX) \
    --sysroot=$(NDK_SYSROOT) \
    --enable-shared \
    --enable-static \
    --enable-avresample \
	--extra-cflags='$(arch_variant_cflags)' \
	--extra-ldflags='$(arch_variant_ldflags)'


include $(ANDROID_BUILD_TOP)/build/core/combo/arch/$(TARGET_ARCH)/$(TARGET_ARCH_VARIANT).mk

# Do not edit after this line
#===============================================================================

FF_LAST_CONFIGURATION_STRING_COMMAND := \
    cat $(FFMPEG_ROOT_DIR)/$(FFMPEG_CONFIG_DIR)/LAST_CONFIGURATION_STRING;
FF_LAST_CONFIGURATION_STRING_OUTPUT := $(shell $(FF_LAST_CONFIGURATION_STRING_COMMAND))

#===============================================================================
ifneq ($(FF_CONFIGURATION_STRING), $(FF_LAST_CONFIGURATION_STRING_OUTPUT))

FF_CREATE_CONFIG_DIR_COMMAND := \
    cd $(FFMPEG_ROOT_DIR); \
    rm -rf $(FFMPEG_CONFIG_DIR); \
    mkdir -p $(FFMPEG_CONFIG_DIR); \
    cd $$OLDPWD;

$(warning ============================================================)
$(warning Creating configuration directory...)
$(warning $(FF_CREATE_CONFIG_DIR_COMMAND))
FF_CREATE_CONFIG_DIR_OUTPUT := $(shell $(FF_CREATE_CONFIG_DIR_COMMAND))
$(warning Done.)
$(warning ============================================================)

FF_CREATE_REQUIRED_FILES_COMMAND := \
    cd $(FFMPEG_ROOT_DIR)/$(FFMPEG_CONFIG_DIR); \
    ../../configure \
--arch=$(TARGET_ARCH) \
--target-os=linux \
--enable-cross-compile \
--cross-prefix=$(NDK_CROSS_PREFIX) \
--sysroot=$(NDK_SYSROOT) \
        --enable-shared \
        --enable-static \
        --enable-gpl \
        --enable-avresample \
        --disable-everything \
        --disable-yasm; \
    make -j; \
    cd $$OLDPWD;

$(warning ============================================================)
$(warning Creating required files...)
$(warning $(FF_CREATE_REQUIRED_FILES_COMMAND))
FF_CREATE_REQUIRED_FILES_OUTPUT := $(shell $(FF_CREATE_REQUIRED_FILES_COMMAND))
$(warning Done.)
$(warning ============================================================)

FF_CONFIGURATION_COMMAND := \
    cd $(FFMPEG_ROOT_DIR)/$(FFMPEG_CONFIG_DIR); \
    ../../configure $(FF_CONFIGURATION_STRING); \
    cd $$OLDPWD;

$(warning ============================================================)
$(warning Configuring FFmpeg...)
$(warning $(FF_CONFIGURATION_COMMAND))
FF_CONFIGURATION_OUTPUT := $(shell $(FF_CONFIGURATION_COMMAND))
$(warning Done.)
$(warning ============================================================)


FF_FIX_CONFIGURATION_COMMAND := \
    cd $(FFMPEG_ROOT_DIR)/$(FFMPEG_CONFIG_DIR); \
    \
    cat config.h | \
    sed 's/\#define av_restrict /\#ifdef av_restrict\n\#undef av_restrict\n\#endif\n\#define av_restrict /g' | \
    sed 's/\#define ARCH_ARM /\#ifdef ARCH_ARM\n\#undef ARCH_ARM\n\#endif\n\#define ARCH_ARM /g' | \
    sed 's/\#define ARCH_MIPS /\#ifdef ARCH_MIPS\n\#undef ARCH_MIPS\n\#endif\n\#define ARCH_MIPS /g' | \
    sed 's/\#define ARCH_X86 /\#ifdef ARCH_X86\n\#undef ARCH_X86\n\#endif\n\#define ARCH_X86 /g' | \
    sed 's/\#define HAVE_PTHREADS/\#ifdef HAVE_PTHREADS\n\#undef HAVE_PTHREADS\n\#endif\n\#define HAVE_PTHREADS/g' | \
    sed 's/\#define HAVE_MALLOC_H/\#ifdef HAVE_MALLOC_H\n\#undef HAVE_MALLOC_H\n\#endif\n\#define HAVE_MALLOC_H/g' | \
    sed 's/\#define HAVE_STRERROR_R 1/\#define HAVE_STRERROR_R 0/g' | \
    sed 's/\#define HAVE_SYSCTL 1/\#define HAVE_SYSCTL 0/g' | \
    cat > config.h.tmp; \
    mv config.h config.h.bak; \
    mv config.h.tmp config.h; \
    \
    cat config.mak | \
    sed 's/HAVE_STRERROR_R=yes/!HAVE_STRERROR_R=yes/g' | \
    sed 's/HAVE_SYSCTL=yes/!HAVE_SYSCTL=yes/g' | \
    cat > config.mak.tmp; \
    mv config.mak config.mak.bak; \
    mv config.mak.tmp config.mak; \
    \
    cd $(OLDPWD);

$(warning ============================================================)
$(warning Fixing configuration...)
#$(warning $(FF_FIX_CONFIGURATION_COMMAND))
FF_FIX_CONFIGURATION_OUTPUT := $(shell $(FF_FIX_CONFIGURATION_COMMAND))
$(warning Done.)
$(warning ============================================================)

FF_FIX_MAKEFILES_COMMAND := \
    cd $(FFMPEG_ROOT_DIR); \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavcodec/Makefile     > libavcodec/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavdevice/Makefile    > libavdevice/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavfilter/Makefile    | \
        sed 's/clean::/\#clean::/g'                                                                           | \
        sed 's/\t$$(RM) $$(CLEANSUFFIXES/\#\t$$(RM) $$(CLEANSUFFIXES/g'                                       > libavfilter/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavformat/Makefile    > libavformat/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavresample/Makefile  > libavresample/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libavutil/Makefile      > libavutil/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libpostproc/Makefile    > libpostproc/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libswresample/Makefile  > libswresample/Makefile.android; \
        sed 's/include $$(SUBDIR)..\/config.mak/\#include $$(SUBDIR)..\/config.mak/g' libswscale/Makefile     > libswscale/Makefile.android; \
        cd $$OLDPWD;

$(warning ============================================================)
$(warning Fixing Makefiles...)
#$(warning $(FF_FIX_MAKEFILES_COMMAND))
FF_FIX_MAKEFILES_OUTPUT := $(shell $(FF_FIX_MAKEFILES_COMMAND))
$(warning Done.)
$(warning ============================================================)

#Saving configuration
FF_LAST_CONFIGURATION_STRING_COMMAND := \
    echo "$(FF_CONFIGURATION_STRING)" > $(FFMPEG_ROOT_DIR)/$(FFMPEG_CONFIG_DIR)/LAST_CONFIGURATION_STRING
FF_LAST_CONFIGURATION_STRING_OUTPUT := $(shell $(FF_LAST_CONFIGURATION_STRING_COMMAND))

endif
