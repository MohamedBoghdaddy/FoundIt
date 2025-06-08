import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../../services/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  AuthCubit(this._authService) : super(AuthInitial());

  void sendOtp(String email) async {
    emit(AuthLoading());
    try {
      await _authService.sendFirebaseOtp(email);
      emit(OtpSent());
    } catch (e) {
      emit(AuthError("Failed to send OTP: \$e"));
    }
  }

  void verifyOtp(String email, String otp) async {
    emit(AuthLoading());
    try {
      final isValid = await _authService.verifyOtp(email, otp);
      if (isValid) {
        emit(OtpVerified());
      } else {
        emit(AuthError("Invalid OTP"));
      }
    } catch (e) {
      emit(AuthError("Failed to verify OTP: \$e"));
    }
  }

  void register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    emit(AuthLoading());
    try {
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _authService.uploadProfileImage(imageFile, email);
      } else if (imageBytes != null) {
        imageUrl = await _authService.uploadProfileBytes(imageBytes, email);
      }

      await _authService.registerUser(
        email,
        password,
        firstName,
        lastName,
        imageUrl: imageUrl,
      );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError("Registration failed: \$e"));
    }
  }

  void login({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authService.loginUser(email, password);
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthError("Login failed: \$e"));
    }
  }

  void resetPassword({required String email}) async {
    emit(AuthLoading());
    try {
      await _authService.resetPassword(email);
      emit(PasswordResetSuccess());
    } catch (e) {
      emit(AuthError("Failed to send reset email: $e"));
    }
  }

}
