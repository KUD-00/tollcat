#include "CSecret.h"

#include <stdlib.h>
#include <string.h>

#if defined(__linux__)

#include <dlfcn.h>

typedef struct {
    const char *name;
    int type;
} SecretSchemaAttribute;

typedef struct {
    const char *name;
    int flags;
    SecretSchemaAttribute attributes[32];
} SecretSchema;

static SecretSchema schema = {
    .name = "app.tollcat.Credential",
    .flags = 0,
    .attributes = {
        { .name = "reference", .type = 0 },
        { .name = NULL, .type = 0 },
    },
};

typedef int (*store_fn)(
    const void *schema,
    const char *collection,
    const char *label,
    const char *password,
    void *cancellable,
    void **error,
    const char *attr_name,
    const char *attr_value,
    void *end
);

typedef char *(*lookup_fn)(
    const void *schema,
    void *cancellable,
    void **error,
    const char *attr_name,
    const char *attr_value,
    void *end
);

typedef int (*clear_fn)(
    const void *schema,
    void *cancellable,
    void **error,
    const char *attr_name,
    const char *attr_value,
    void *end
);

typedef void (*free_fn)(char *value);

static void *libsecret(void) {
    static void *handle;
    static int tried;
    if (!tried) {
        tried = 1;
        handle = dlopen("libsecret-1.so.0", RTLD_NOW | RTLD_GLOBAL);
    }
    return handle;
}

int tollcat_secret_available(void) {
    return libsecret() != NULL;
}

int tollcat_secret_store(const char *reference, const char *secret) {
    void *handle = libsecret();
    if (!handle || !reference || !secret) return 0;
    store_fn store = (store_fn)dlsym(handle, "secret_password_store_sync");
    if (!store) return 0;
    return store(&schema, "default", "TollCat", secret, NULL, NULL, "reference", reference, NULL);
}

char *tollcat_secret_lookup(const char *reference) {
    void *handle = libsecret();
    if (!handle || !reference) return NULL;
    lookup_fn lookup = (lookup_fn)dlsym(handle, "secret_password_lookup_sync");
    if (!lookup) return NULL;
    return lookup(&schema, NULL, NULL, "reference", reference, NULL);
}

int tollcat_secret_clear(const char *reference) {
    void *handle = libsecret();
    if (!handle || !reference) return 0;
    clear_fn clear = (clear_fn)dlsym(handle, "secret_password_clear_sync");
    if (!clear) return 0;
    clear(&schema, NULL, NULL, "reference", reference, NULL);
    return 1;
}

void tollcat_secret_free(char *value) {
    if (!value) return;
    void *handle = libsecret();
    if (handle) {
        free_fn release = (free_fn)dlsym(handle, "secret_password_free");
        if (release) {
            release(value);
            return;
        }
    }
    free(value);
}

#else

int tollcat_secret_available(void) { return 0; }

int tollcat_secret_store(const char *reference, const char *secret) {
    (void)reference;
    (void)secret;
    return 0;
}

char *tollcat_secret_lookup(const char *reference) {
    (void)reference;
    return NULL;
}

int tollcat_secret_clear(const char *reference) {
    (void)reference;
    return 1;
}

void tollcat_secret_free(char *value) {
    (void)value;
}

#endif
