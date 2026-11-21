import 'package:ticketsur/features/security/domain/admin_mfa.dart';

/// Double authentification en mémoire : le code valide est [validCode],
/// les codes de secours [codes].
class FakeAdminMfaRepository implements AdminMfaRepository {
  new({this.enrolled = false, this.aal2 = false});

  bool enrolled;
  bool aal2;
  String validCode = '123456';
  List<String> codes = [];
  final List<String> calls = [];
  MfaFailure? failure;

  static const _generated = [
    'ABCDE-FGHJK',
    'MNPQR-STUVW',
    'XYZ23-45678',
    'AAAAA-BBBBB',
    'CCCCC-DDDDD',
    'EEEEE-FFFFF',
    'GGGGG-HHHHH',
    'JJJJJ-KKKKK',
  ];

  @override
  Future<AdminMfaStatus> status() async {
    calls.add('status');
    if (failure case final f?) throw f;
    return AdminMfaStatus(
      enrolled: enrolled,
      aal2: aal2,
      recoveryCodesLeft: codes.length,
    );
  }

  @override
  Future<MfaEnrollment> enroll() async {
    calls.add('enroll');
    if (failure case final f?) throw f;
    return (
      factorId: 'factor-1',
      uri: 'otpauth://totp/Tik%C3%A9o:admin?secret=JBSWY3DPEHPK3PXP',
      secret: 'JBSWY3DPEHPK3PXP',
    );
  }

  @override
  Future<void> verify(String code, {String? factorId}) async {
    calls.add('verify ${factorId ?? 'session'}');
    if (code != validCode) throw MfaFailure.invalidCode;
    enrolled = true;
    aal2 = true;
  }

  @override
  Future<List<String>> generateRecoveryCodes() async {
    calls.add('codes');
    codes = [..._generated];
    return [...codes];
  }

  @override
  Future<bool> useRecoveryCode(String code) async {
    calls.add('recovery');
    final normalized = code.toUpperCase();
    if (!codes.contains(normalized)) return false;
    enrolled = false;
    aal2 = false;
    codes = [];
    return true;
  }

  @override
  Future<void> disable() async {
    calls.add('disable');
    enrolled = false;
    codes = [];
  }
}
