import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/presentation/cubits/dashboard/dashboard_cubit.dart';
import 'package:quarto/features/dashboard/presentation/cubits/rooms/rooms_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboardStats();
    context.read<RoomsCubit>().loadRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 30),
          child: Column(
            children: [
              //first conatiner
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.bgDark,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Total Free Rooms",
                          style: AppTexts.smallHeading,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "5",
                          style: AppTexts.largeHeading,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Total Occupied Rooms",
                          style: AppTexts.smallHeading,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "4",
                          style: AppTexts.largeHeading,
                        ),
                      ],
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Today Incomes",
                          style: AppTexts.smallHeading,
                        ),
                        SizedBox(height: 12),
                        Text(
                          "360",
                          style: AppTexts.largeHeading,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              //second body
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.bgDark,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    "Today",
                                    style: AppTexts.meduimBody,
                                  ),
                                  Text(
                                    "Yasterday",
                                    style: AppTexts.meduimBody,
                                  ),
                                  Text(
                                    "Custom Date",
                                    style: AppTexts.meduimBody,
                                  ),
                                ],
                              ),
                              Divider(color: AppColors.borderLight),
                              SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                spacing: 12,
                                runSpacing: 12,

                                children: [
                                  // card items
                                  _cardWidget(status: "Free", title: "Room1"),
                                  _cardWidget(
                                    status: "Occupied",
                                    title: "Room2",
                                  ),
                                  _cardWidget(status: "Free", title: "Room3"),
                                  _cardWidget(status: "Free", title: "Room4"),
                                  _cardWidget(
                                    status: "Occupied",
                                    title: "Room5",
                                  ),
                                  _cardWidget(status: "Free", title: "Room6"),
                                  _cardWidget(status: "Free", title: "Room7"),
                                  _cardWidget(status: "Free", title: "Room8"),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  // room details part
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.bgDark,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Room 3 - Details",
                            style: AppTexts.smallHeading,
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Current Session",
                            style: AppTexts.meduimBody,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Start Time",
                            style: AppTexts.smallBody,
                          ),
                          SizedBox(height: 6),
                          Text("14:40", style: AppTexts.meduimBody),
                          SizedBox(height: 12),
                          Text("Timer", style: AppTexts.smallBody),
                          SizedBox(height: 6),
                          Text("1h 40m", style: AppTexts.meduimBody),
                          SizedBox(height: 20),
                          Text(
                            "Today History",
                            style: AppTexts.meduimBody,
                          ),
                          SizedBox(height: 12),
                          // Table
                          DataTable(
                            dataTextStyle: TextStyle(color: Colors.white),
                            headingTextStyle: TextStyle(color: Colors.white),
                            border: TableBorder.all(
                              color: AppColors.borderLight,
                            ),
                            headingRowColor: WidgetStateProperty.all(
                              AppColors.borderColor,
                            ),
                            columnSpacing: 40,
                            horizontalMargin: 20,
                            columns: const [
                              DataColumn(label: Text("#")),
                              DataColumn(label: Text("Start")),
                              DataColumn(label: Text("End")),
                              DataColumn(label: Text("Duration")),
                              DataColumn(label: Text("Cost")),
                            ],
                            rows: List.generate(4, (i) {
                              return DataRow(
                                cells: [
                                  DataCell(Text("${i + 1}")),
                                  DataCell(Text("10:00")),
                                  DataCell(Text("11:30")),
                                  DataCell(Text("1h 30m")),
                                  DataCell(Text("150")),
                                ],
                              );
                            }),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Total of day: 600",
                            style: TextStyle(color: Colors.white),
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
      ),
    );
  }
}

Widget _cardWidget({required String title, required String status}) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: AppColors.bgCardLight,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTexts.smallHeading),
        SizedBox(height: 4),
        Text(
          status,
          style: AppTexts.meduimBody.copyWith(
            color:
                status == "Occupied" ? Colors.deepOrange : AppColors.statusFree,
          ),
        ),
        if (status == "Free") ...[SizedBox(height: 40)],
        if (status == "Occupied") ...[
          SizedBox(height: 8),
          Text("Start: 14:10", style: AppTexts.smallBody),
          SizedBox(height: 4),
          Text("Live Duration 1h 10m", style: AppTexts.smallBody),
          SizedBox(height: 4),
          Text("Current Cost 110", style: AppTexts.smallBody),
        ],

        SizedBox(height: 12),
        MaterialButton(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minWidth: 150,
          onPressed: () {},
          color: status == "Occupied" ? Colors.red : AppColors.primaryBlue,
          child: Text(
            status == "Occupied" ? "End Session" : "Start Session",
            style: AppTexts.smallBody,
          ),
        ),
      ],
    ),
  );
}
