import 'package:flutter/material.dart';
import 'package:quarto/core/colors/app_colors.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

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
                  vertical: 30,
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Total Free Rooms",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "5",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Total Occupied Rooms",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "4",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Today Incomes",
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 12),
                        Text(
                          "360",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                          ),
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
                    // flex: 2,
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
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    "Yasterday",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    "Custom Date",
                                    style: TextStyle(color: Colors.white),
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
                                  _cardWidget(status: "Free", title: "Room2"),
                                  _cardWidget(status: "Free", title: "Room3"),
                                  _cardWidget(status: "Free", title: "Room4"),
                                  _cardWidget(status: "Free", title: "Room5"),
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
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          Text(
                            "Current Session",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Start Time",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "14:40",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Timer",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "1h 40m",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 12),
                          Text(
                            "Today History",
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 20),
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
        Text(
          title,
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 6),
        Text(
          status,
          style: TextStyle(
            color: AppColors.statusFree,
          ),
        ),
        SizedBox(height: 12),
        MaterialButton(
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(12),
          ),
          minWidth: 150,
          onPressed: () {},
          color: AppColors.primaryBlue,
          child: Text(
            "Start Session",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ),
  );
}
