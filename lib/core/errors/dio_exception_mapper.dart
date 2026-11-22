import 'package:dio/dio.dart';

import 'api_error_code.dart';
import 'api_exception.dart';

/// Dio 오류를 공통 예외 [ApiException] 으로 바꿉니다.
///
/// 각 기능의 Repository 가 DataSource 호출을 감싸서 씁니다. DataSource 에서는 예외를 잡지 않습니다.
extension DioExceptionMapperX on DioException {
  ApiException toApiException() {
    final response = this.response;
    if (response == null) {
      // 응답은 받았지만 본문을 해석하지 못한 경우. Dio 는 response 없이 넘깁니다.
      // - 잘못된 JSON: FormatException
      // - 최상위가 배열·문자열 등 기대한 타입이 아님: Dio 가 변환 중 난 TypeError(Error) 를 감쌉니다.
      // 연결 실패·시간 초과는 SocketException 등 Exception 이라 여기에 걸리지 않습니다.
      if (error is FormatException || error is Error) {
        return const ApiException(code: ApiErrorCode.unknown);
      }
      // 응답 자체를 받지 못한 경우 (연결 실패, 시간 초과, 요청 취소 등)
      return const ApiException(code: ApiErrorCode.network);
    }

    final body = response.data;
    // 디코더 설정에 따라 Map<dynamic, dynamic> 으로 올 수 있어 Map 으로 검사합니다.
    final errorBody = body is Map ? body['error'] : null;
    final code = errorBody is Map ? errorBody['code'] : null;
    final message = errorBody is Map ? errorBody['message'] : null;
    return ApiException(
      // 실패 응답에 code 가 없으면 HTTP 상태 코드로 보완합니다.
      code: code != null
          ? ApiErrorCode.fromServer(code)
          : ApiErrorCode.fromStatusCode(response.statusCode),
      message: message is String ? message : null,
    );
  }
}
