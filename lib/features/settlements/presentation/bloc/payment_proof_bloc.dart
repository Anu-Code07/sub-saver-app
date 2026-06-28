import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:subsaver/core/services/ocr_service.dart';
import 'package:subsaver/core/utils/payment_receipt_parser.dart';
import 'package:subsaver/features/settlements/domain/repositories/payment_proof_repository.dart';

sealed class PaymentProofEvent extends Equatable {
  const PaymentProofEvent();

  @override
  List<Object?> get props => [];
}

class PaymentProofImageSelected extends PaymentProofEvent {
  const PaymentProofImageSelected(this.localImagePath);

  final String localImagePath;

  @override
  List<Object?> get props => [localImagePath];
}

class PaymentProofResetRequested extends PaymentProofEvent {
  const PaymentProofResetRequested();
}

class PaymentProofSubmitRequested extends PaymentProofEvent {
  const PaymentProofSubmitRequested({
    required this.groupId,
    required this.expenseId,
    required this.subscriptionId,
    required this.uploadedBy,
  });

  final String groupId;
  final String expenseId;
  final String subscriptionId;
  final String uploadedBy;

  @override
  List<Object?> get props => [groupId, expenseId, subscriptionId, uploadedBy];
}

class PaymentProofState extends Equatable {
  const PaymentProofState({
    this.localImagePath,
    this.ocrText,
    this.parsedAmount,
    this.referenceId,
    this.isScanning = false,
    this.isUploading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  final String? localImagePath;
  final String? ocrText;
  final double? parsedAmount;
  final String? referenceId;
  final bool isScanning;
  final bool isUploading;
  final bool isSuccess;
  final String? errorMessage;

  PaymentProofState copyWith({
    String? localImagePath,
    String? ocrText,
    double? parsedAmount,
    String? referenceId,
    bool? isScanning,
    bool? isUploading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PaymentProofState(
      localImagePath: localImagePath ?? this.localImagePath,
      ocrText: ocrText ?? this.ocrText,
      parsedAmount: parsedAmount ?? this.parsedAmount,
      referenceId: referenceId ?? this.referenceId,
      isScanning: isScanning ?? this.isScanning,
      isUploading: isUploading ?? this.isUploading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        localImagePath,
        ocrText,
        parsedAmount,
        referenceId,
        isScanning,
        isUploading,
        isSuccess,
        errorMessage,
      ];
}

class PaymentProofBloc extends Bloc<PaymentProofEvent, PaymentProofState> {
  PaymentProofBloc({
    required OcrService ocrService,
    required PaymentProofRepository paymentProofRepository,
  })  : _ocrService = ocrService,
        _paymentProofRepository = paymentProofRepository,
        super(const PaymentProofState()) {
    on<PaymentProofResetRequested>((event, emit) => emit(const PaymentProofState()));
    on<PaymentProofImageSelected>(_onImageSelected);
    on<PaymentProofSubmitRequested>(_onSubmitRequested);
  }

  final OcrService _ocrService;
  final PaymentProofRepository _paymentProofRepository;

  Future<void> _onImageSelected(
    PaymentProofImageSelected event,
    Emitter<PaymentProofState> emit,
  ) async {
    emit(PaymentProofState(
      localImagePath: event.localImagePath,
      isScanning: true,
    ));

    try {
      final text = await _ocrService.recognizeFromFile(event.localImagePath);
      final parsed = PaymentReceiptParser.parse(text);
      emit(state.copyWith(
        ocrText: text,
        parsedAmount: parsed.amount,
        referenceId: parsed.referenceId,
        isScanning: false,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        isScanning: false,
        errorMessage: 'Could not scan payment screenshot. Please try another image.',
      ));
    }
  }

  Future<void> _onSubmitRequested(
    PaymentProofSubmitRequested event,
    Emitter<PaymentProofState> emit,
  ) async {
    final imagePath = state.localImagePath;
    if (imagePath == null) {
      emit(state.copyWith(errorMessage: 'Choose a payment screenshot first.'));
      return;
    }

    emit(state.copyWith(isUploading: true, clearError: true));
    try {
      await _paymentProofRepository.uploadProof(
        groupId: event.groupId,
        expenseId: event.expenseId,
        subscriptionId: event.subscriptionId,
        uploadedBy: event.uploadedBy,
        localImagePath: imagePath,
        ocrText: state.ocrText,
        amount: state.parsedAmount,
        referenceId: state.referenceId,
      );
      emit(state.copyWith(isUploading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isUploading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
