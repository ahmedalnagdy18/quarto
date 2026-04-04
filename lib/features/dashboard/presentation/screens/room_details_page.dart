import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/common/room_order_dailoge_widget.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/cubits/session_history/session_history_cubit.dart';
import 'package:quarto/features/dashboard/presentation/screens/session_details_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/button_widget.dart';
import 'package:quarto/features/dashboard/presentation/widgets/order_list_widget.dart';

class RoomDetailsPage extends StatefulWidget {
  const RoomDetailsPage({super.key, required this.room});
  final Room room;
  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  final TextEditingController commentsController = TextEditingController();
  @override
  void initState() {
    context.read<SessionHistoryCubit>().loadRoomHistory(widget.room.id);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              'images/bg.png',
              fit: BoxFit.cover,
            ),
          ),
          BlocListener<SessionHistoryCubit, SessionHistoryState>(
            listener: (context, state) {
              if (state is SuccessAddComment) {
                commentsController.clear();
              }
            },
            child: BlocBuilder<SessionHistoryCubit, SessionHistoryState>(
              builder: (context, state) {
                if (state is SessionHistoryLoaded) {
                  SessionHistory? activeSession;

                  try {
                    activeSession = state.history.firstWhere(
                      (e) => e.endTime == null,
                    );
                  } catch (e) {
                    activeSession = null;
                  }
                  final activeComments = activeSession?.comments ?? [];
                  final activeOrders = activeSession?.ordersList ?? [];
                  final now = DateTime.now();

                  final start = widget.room.sessionStart;
                  final duration = start != null
                      ? now.difference(start)
                      : Duration.zero;
                  final hours = duration.inMinutes / 60.0;
                  final liveSegmentCost = hours * widget.room.hourlyRate;
                  final currentCost = activeSession == null
                      ? 0.0
                      : activeSession.totalCost + liveSegmentCost;

                  String formatDuration(Duration d) {
                    final hours = d.inHours;
                    final minutes = d.inMinutes % 60;
                    return '${hours}h ${minutes}m';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Image.asset(
                                'images/quarto_logo.png',
                                scale: 4,
                              ),
                              const Spacer(),
                              ExportButtonsWidget(
                                title: 'Export history',
                                icon: Icons.download,
                                onPressed: () {},
                              ),
                              const SizedBox(width: 20),
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                child: AddButton(
                                  title: 'Add order',
                                  onPressed: activeSession != null
                                      ? () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return RoomOrderDailogeWidget(
                                                roomId: widget.room.id,
                                                sessionId: activeSession?.id,
                                              );
                                            },
                                          );
                                        }
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${widget.room.name} - Activity Overview',
                                style: const TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 36),
                            child: Text(
                              'Current player session details and transaction logs.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Active Session',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: activeSessionCard(
                                  icon: Icons.timelapse_sharp,
                                  title: 'Duration',
                                  data: start != null
                                      ? formatDuration(duration)
                                      : '--',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: activeSessionCard(
                                  icon: Icons.people_alt_outlined,
                                  title: 'Type',
                                  data: !widget.room.isOccupied
                                      ? '--'
                                      : widget.room.isMulti == true
                                      ? 'Multi'
                                      : 'Single',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: activeSessionCard(
                                  icon: Icons.play_arrow_outlined,
                                  title: 'Start',
                                  data: start != null
                                      ? '${start.hour}:${start.minute}'
                                      : '--',
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: activeSessionCard(
                                  icon: Icons.attach_money,
                                  title: 'Current Cost',
                                  data: start != null
                                      ? '${currentCost.toStringAsFixed(0)} \$'
                                      : '0 \$',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: commentsCardWidget(
                                  widget: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            Icons.chat_outlined,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Session Comments',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 1,
                                              color: Colors.white10,
                                              spreadRadius: 0,
                                              offset: Offset(0, 0),
                                            ),
                                          ],
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          color: Colors.transparent,
                                          border: Border.all(
                                            color: Colors.white10,
                                          ),
                                        ),
                                        child: TextField(
                                          enabled: activeSession != null,
                                          controller: commentsController,
                                          maxLines: 3,
                                          minLines: 2,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'Add new comment',
                                            hintStyle: TextStyle(
                                              color: Colors.white,
                                            ),
                                            border: UnderlineInputBorder(
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: AddButton(
                                          title: 'Add comment',
                                          onPressed: () {
                                            if (activeSession == null) return;
                                            if (commentsController.text
                                                .trim()
                                                .isNotEmpty) {
                                              context
                                                  .read<SessionHistoryCubit>()
                                                  .addCommentFunc(
                                                    comments:
                                                        commentsController.text,
                                                    roomId: widget.room.id,
                                                    sessionId: activeSession.id,
                                                  );
                                            }
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: activeSession == null
                                            ? const Center(
                                                child: Text(
                                                  'No active session',
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              )
                                            : activeComments.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'There\'s no comments yet',
                                                  style: TextStyle(
                                                    color: Colors.white60,
                                                  ),
                                                ),
                                              )
                                            : ListView.separated(
                                                itemCount:
                                                    activeComments.length,
                                                itemBuilder: (context, index) {
                                                  final comment =
                                                      activeComments[index];

                                                  return Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Icon(
                                                        Icons.person,
                                                        color: Colors.white60,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          comment.toString(),
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white60,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(height: 12),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 30),
                              Expanded(
                                child: commentsCardWidget(
                                  widget: activeSession == null
                                      ? const Center(
                                          child: Text(
                                            'No active session',
                                            style: TextStyle(
                                              color: Colors.white60,
                                            ),
                                          ),
                                        )
                                      : activeOrders.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'There\'s no Orders yet',
                                            style: TextStyle(
                                              color: Colors.white60,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.list,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Order details',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            Expanded(
                                              child: buildOrdersList(
                                                activeOrders,
                                              ),
                                            ),
                                            const Divider(),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Total',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${activeSession.ordersTotal.toStringAsFixed(0)} EGP',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Today history',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 30),
                          _buildHistoryTable(
                            state.history,
                            widget.room,
                            context,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColors.yellowColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget activeSessionCard({
  required IconData icon,
  required String title,
  required String data,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      boxShadow: const [
        BoxShadow(
          blurRadius: 1,
          color: Colors.white10,
          spreadRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      border: Border.all(color: Colors.white10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        const Spacer(),
        Text(
          data,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget commentsCardWidget({
  required Widget widget,
}) {
  return Container(
    height: 300,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      boxShadow: const [
        BoxShadow(
          blurRadius: 1,
          color: Colors.white10,
          spreadRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      color: Colors.transparent,
      border: Border.all(color: Colors.white10),
    ),
    child: widget,
  );
}

Widget _buildHistoryTable(
  List<SessionHistory> history,
  Room room,
  BuildContext context,
) {
  double calculateSessionCost(SessionHistory session) {
    final sessionCost = session.totalCost - session.ordersTotal;
    return sessionCost < 0 ? 0.0 : sessionCost;
  }

  return SizedBox(
    width: double.infinity,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width,
      ),
      child: DataTable(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 1,
              color: Colors.white10,
              spreadRadius: 0,
              offset: Offset(0, 0),
            ),
          ],
        ),
        dataTextStyle: const TextStyle(color: Colors.white),
        headingTextStyle: const TextStyle(color: Colors.white),
        border: TableBorder.all(color: Colors.white10),
        headingRowColor: const WidgetStatePropertyAll(Colors.transparent),
        horizontalMargin: 12,
        columns: const [
          DataColumn(
            label: Text('#'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Start'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('End'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Duration'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Session'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Orders'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Total'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
          DataColumn(
            label: Text('Details'),
            headingRowAlignment: MainAxisAlignment.center,
          ),
        ],
        rows: history.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;

          final sessionCost = calculateSessionCost(session);
          final ordersCost = session.ordersTotal;
          final totalCost = session.totalCost;

          return DataRow(
            cells: [
              DataCell(Center(child: Text('${index + 1}'))),
              DataCell(Center(child: Text(session.startTimeShort))),
              DataCell(
                Center(
                  child: Text(
                    session.endTime != null ? session.endTimeShort : 'Running',
                  ),
                ),
              ),
              DataCell(Center(child: Text(session.formattedDuration))),
              DataCell(
                Center(child: Text('${sessionCost.toStringAsFixed(0)} EGP')),
              ),
              DataCell(
                Center(
                  child: Text(
                    '${ordersCost.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: Text(
                    '${totalCost.toStringAsFixed(0)} EGP',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: ElevatedButton.icon(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(
                        AppColors.yellowColor,
                      ),
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12,
                        ),
                      ),
                      side: WidgetStatePropertyAll(
                        BorderSide(
                          width: 3,
                          color: AppColors.yellowColor,
                        ),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => SessionDetailsPage(
                            history: history[index],
                            room: room,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.remove_red_eye_outlined,
                      color: AppColors.blueColor,
                      size: 14,
                    ),
                    label: Text(
                      'View',
                      style: TextStyle(
                        color: AppColors.blueColor,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ),
  );
}
