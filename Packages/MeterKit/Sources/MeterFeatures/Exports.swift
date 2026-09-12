/// SpokenMoney / MeterDateFormat / DisplayCurrencyCopy 挪去了 MeterFormat
/// （Widget 也要用，不能住在 Widget 链接不到的这里）。
/// re-export 让本模块几十个调用点不用逐个补 import。
@_exported import MeterFormat
