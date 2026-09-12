#if os(Android)
import Android
import Foundation

enum JNISupport {
    /// JNI 拿字符串失败（OOM 或已挂起的异常）时清掉异常、回空串——
    /// 空串走各自的「解不出就空态」路径，不能让 force-unwrap 把进程带崩。
    static func string(_ env: UnsafeMutablePointer<JNIEnv?>, _ value: jstring?) -> String {
        guard let value else { return "" }
        let jni = env.pointee!.pointee
        guard let chars = jni.GetStringUTFChars(env, value, nil) else {
            if jni.ExceptionCheck(env) != 0 {
                jni.ExceptionClear(env)
            }
            return ""
        }
        defer { jni.ReleaseStringUTFChars(env, value, chars) }
        return String(cString: chars)
    }

    /// NewStringUTF 失败返回 NULL 并挂起 OutOfMemoryError，
    /// 原样交回 Java 让它按异常抛，不在 native 侧解引用。
    static func newString(_ env: UnsafeMutablePointer<JNIEnv?>, _ value: String) -> jstring? {
        value.withCString { ptr in
            env.pointee!.pointee.NewStringUTF(env, ptr)
        }
    }
}
#endif
