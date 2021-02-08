import 'package:shared_preferences/shared_preferences.dart';

class CommonPreferences {
  CommonPreferences._();

  static final _instance = CommonPreferences._();

  /// 用create函数获取commonPref类单例
  factory CommonPreferences() => _instance;

  static SharedPreferences getPref() => _instance._sharedPref;

  SharedPreferences _sharedPref;

  /// 初始化sharedPrefs，在自动登录时就被调用
  static Future<void> initPrefs() async {
    _instance._sharedPref = await SharedPreferences.getInstance();

    /// 处理一些比较特殊的缓存默认值
    if (_instance.dayNumber.value == 0) _instance.dayNumber.value = 7;
    if (_instance.language.value == "") _instance.language.value = "简体中文";
    // TODO debug
    _instance.isBindTju.value = false;
  }

  ///twt相关

  var isLogin = PrefsBean<bool>('login');
  var token = PrefsBean<String>('token');
  var nickname = PrefsBean<String>('nickname');
  var userNumber = PrefsBean<String>('userNumber');
  var phone = PrefsBean<String>('phone');
  var email = PrefsBean<String>('email');
  var account = PrefsBean<String>('account');
  var password = PrefsBean<String>('password');
  var captchaCookie = PrefsBean<String>('Cookie');

  ///办公网相关

  var isBindTju = PrefsBean<bool>('bindtju');
  var tjuuname = PrefsBean<String>('tjuuname');
  var tjupasswd = PrefsBean<String>('tjupasswd');

  /// cookies in sso.tju.edu.cn，暂时先不存了
  // var tgc = PrefsBean<String>("tgc");

  /// cookies in classes.tju.edu.cn
  var gSessionId = PrefsBean<String>("gsessionid"); // GSESSIONID
  var garbled = PrefsBean<String>("garbled"); // UqZBpD3n3iXPAw1X
  var semesterId = PrefsBean<String>("semester"); // semester.id
  var ids = PrefsBean<String>("ids"); // ids

  /// 设置页面
  var language = PrefsBean<String>("language"); // 系统语言
  var dayNumber = PrefsBean<int>("dayNumber"); // 每周显示天数
  var hideGPA = PrefsBean<bool>("hideGPA"); // 首页不显示GPA
  var nightMode = PrefsBean<bool>("nightMode"); // 开启夜猫子模式
  var otherWeekSchedule = PrefsBean<bool>("otherWeekSchedule"); // 课表显示非本周课程
  var remindBeforeStart = PrefsBean<bool>("remindBeforeStart"); // 开课前提醒
  var remindBefore = PrefsBean<bool>("remindBefore"); // 课前提醒

  List<String> getCookies() {
    var jSessionId = 'J' + gSessionId.value?.substring(1);
    return [gSessionId.value, jSessionId, garbled.value, semesterId.value];
  }

  /// 重置twt用户的缓存
  void clearPrefs() {
    isLogin.value = false;
    token.value = "";
    nickname.value = "";
    userNumber.value = "";
    phone.value = "";
    email.value = "";
    account.value = "";
    password.value = "";
    captchaCookie.value = "";
    // hideGPA.value = false;
    // nightMode.value = false;
    // otherWeekSchedule.value = false;
    // remindBeforeStart.value = false;
    // remindBefore.value = false;
    // _sharedPref.clear();
  }

  /// 重置办公网缓存
  void clearTjuPrefs() {
    isBindTju.value = false;
    tjuuname.value = "";
    tjupasswd.value = "";
    // tgc.value = "";
    gSessionId.value = "";
    garbled.value = "";
    semesterId.value = "";
    ids.value = "";
  }
}

class PrefsBean<T> {
  PrefsBean(this._key) {
    _default = _getDefault(T);
    _value = _default;
  }

  String _key;
  T _value;
  T _default;

  T get value {
    if (_value == _default) _value = _getValue(T, _key);
    return _value;
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _setValue(newValue, _key);
    _value = newValue;
  }
}

dynamic _getValue<T>(T, String key) {
  var pref = CommonPreferences.getPref();
  return pref?.get(key) ?? _getDefault(T);
}

void _setValue<T>(T value, String key) {
  var pref = CommonPreferences.getPref();
  if (pref == null) return;
  switch (T) {
    case String:
      pref.setString(key, value as String);
      break;
    case bool:
      pref.setBool(key, value as bool);
      break;
    case int:
      pref.setInt(key, value as int);
      break;
    case double:
      pref.setDouble(key, value as double);
      break;
  }
}

dynamic _getDefault<T>(T) {
  switch (T) {
    case String:
      return "";
    case int:
      return 0;
    case double:
      return 0.0;
    case bool:
      return false;
    default:
      return null;
  }
}
