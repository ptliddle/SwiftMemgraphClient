
#ifndef MGCLIENT_EXPORT_H
#define MGCLIENT_EXPORT_H

#ifdef MGCLIENT_STATIC_DEFINE
#  define MGCLIENT_EXPORT
#  define MGCLIENT_NO_EXPORT
#else
#  ifndef MGCLIENT_EXPORT
#    ifdef mgclient_shared_EXPORTS
        /* We are building this library */
#      define MGCLIENT_EXPORT __attribute__((visibility("default")))
#    else
        /* We are using this library */
#      define MGCLIENT_EXPORT __attribute__((visibility("default")))
#    endif
#  endif

#  ifndef MGCLIENT_NO_EXPORT
#    define MGCLIENT_NO_EXPORT __attribute__((visibility("hidden")))
#  endif
#endif

#ifndef MGCLIENT_DEPRECATED
#  define MGCLIENT_DEPRECATED __attribute__ ((__deprecated__))
#endif

#ifndef MGCLIENT_DEPRECATED_EXPORT
#  define MGCLIENT_DEPRECATED_EXPORT MGCLIENT_EXPORT MGCLIENT_DEPRECATED
#endif

#ifndef MGCLIENT_DEPRECATED_NO_EXPORT
#  define MGCLIENT_DEPRECATED_NO_EXPORT MGCLIENT_NO_EXPORT MGCLIENT_DEPRECATED
#endif

/* NOLINTNEXTLINE(readability-avoid-unconditional-preprocessor-if) */
#if 0 /* DEFINE_NO_DEPRECATED */
#  ifndef MGCLIENT_NO_DEPRECATED
#    define MGCLIENT_NO_DEPRECATED
#  endif
#endif

#endif /* MGCLIENT_EXPORT_H */
