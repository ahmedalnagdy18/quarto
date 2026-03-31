import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/features/dashboard/data/model/room_model.dart';
import 'package:quarto/features/dashboard/data/model/session_history_model.dart';
import 'package:quarto/features/dashboard/presentation/screens/room_details_page.dart';
import 'package:quarto/features/dashboard/presentation/widgets/order_list_widget.dart';

class SessionDetailsPage extends StatelessWidget {
  final SessionHistory history;
  final Room room;
  const SessionDetailsPage({
    super.key,
    required this.history,
    required this.room,
  });

  double calculateSessionCost(SessionHistory session) {
    if (session.endTime == null) return 0.0;

    final duration = session.endTime!.difference(session.startTime);
    final hours = duration.inMinutes / 60.0;
    return hours * session.hourlyRate;
  }

  @override
  Widget build(BuildContext context) {
    final sessionCost = calculateSessionCost(history);
    final ordersCost = history.ordersTotal;
    final totalCost = sessionCost + ordersCost;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Bg image
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Image.asset(
              "images/bg.png",
              fit: BoxFit.cover,
            ),
          ),

          // page item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'images/quarto_logo.png',
                  scale: 4,
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.timelapse_sharp,
                        title: 'Duration',
                        data: history.formattedDuration,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.people_alt_outlined,
                        title: 'Type',
                        data: history.sessionTypeInfo,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.play_arrow_outlined,
                        title: 'Start',
                        data: history.startTimeShort,
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.pause_circle_outline,
                        title: 'End',
                        data: history.endTime != null
                            ? history.endTimeShort
                            : "Running",
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                //todo;;;''xcxczxcxzcxzc
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.money,
                        title: 'Session free',
                        data: "${sessionCost.toStringAsFixed(0)} \$",
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: activeSessionCard(
                        icon: Icons.menu,
                        title: 'Orders',
                        data: "${ordersCost.toStringAsFixed(0)} \$",
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      flex: 1,
                      child: totalSessionCard(
                        icon: Icons.euro,
                        title: 'Total',
                        data: "${totalCost.toStringAsFixed(0)} \$",
                      ),
                    ),
                    SizedBox(width: 20),
                    Spacer(flex: 1),
                  ],
                ),

                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: commentsCardWidget(
                        widget: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                            SizedBox(height: 20),
                            Expanded(
                              child: history.comments!.isEmpty
                                  ? Center(
                                      child: Text(
                                        "There's no comments yet",
                                        style: TextStyle(
                                          color: Colors.white60,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: history.comments!.length,
                                      itemBuilder: (context, index) {
                                        final comment =
                                            history.comments![index];

                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: Colors.white60,
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                comment.toString(),
                                                style: TextStyle(
                                                  color: Colors.white60,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 12),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 30),
                    Expanded(
                      child: commentsCardWidget(
                        widget: history.ordersList.isEmpty
                            ? Center(
                                child: Text(
                                  "There's no Orders yet",
                                  style: TextStyle(
                                    color: Colors.white60,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
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
                                  SizedBox(height: 20),
                                  Expanded(
                                    child: buildOrdersList(
                                      history.ordersList,
                                    ),
                                  ),
                                  Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${history.ordersTotal.toStringAsFixed(0)} EGP',
                                        style: TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget totalSessionCard({
  required IconData icon,
  required String title,
  required String data,
}) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      boxShadow: [
        BoxShadow(
          blurRadius: 1,
          color: Colors.white10,
          spreadRadius: 0,
          offset: Offset(0, 0),
        ),
      ],
      borderRadius: BorderRadius.circular(12),
      color: AppColors.yellowColor,
      border: Border.all(color: AppColors.yellowColor),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.blueColor),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: AppColors.blueColor,
          ),
        ),
        Spacer(),
        Text(
          data,
          style: TextStyle(
            color: AppColors.blueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
