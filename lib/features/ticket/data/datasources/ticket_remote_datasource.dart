import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/ticket_model.dart';

class TicketRemoteDataSource {
  final Dio dio;
  TicketRemoteDataSource(this.dio);

  Future<List<TicketModel>> getTickets({String? status, String? search}) async {
    final res = await dio.get(ApiConstants.tickets, queryParameters: {
      if (status != null) 'status': status,
      if (search != null) 'q': search,
    });
    return (res.data['data'] as List)
        .map((e) => TicketModel.fromJson(e))
        .toList();
  }

  Future<TicketModel> getTicketById(String id) async {
    final res = await dio.get(ApiConstants.ticketById(id));
    return TicketModel.fromJson(res.data);
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String priority,
    String? categoryId,
    List<MultipartFile>? attachments,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'description': description,
      'priority': priority,
      if (categoryId != null) 'category_id': categoryId,
      if (attachments != null)
        'attachments': attachments,
    });
    final res = await dio.post(
      ApiConstants.tickets,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TicketModel.fromJson(res.data);
  }

  Future<TicketModel> updateStatus(String id, String status) async {
    final res = await dio.patch(
      ApiConstants.ticketStatus(id),
      data: {'status': status},
    );
    return TicketModel.fromJson(res.data);
  }

  Future<TicketModel> assignTicket(String id, String assigneeId) async {
    final res = await dio.patch(
      ApiConstants.ticketAssign(id),
      data: {'assigned_to': assigneeId},
    );
    return TicketModel.fromJson(res.data);
  }

  Future<void> addComment(String ticketId, String content) async {
    await dio.post(
      ApiConstants.ticketComments(ticketId),
      data: {'content': content},
    );
  }
}