import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quarto/core/colors/app_colors.dart';
import 'package:quarto/core/fonts/app_text.dart';
import 'package:quarto/features/dashboard/presentation/cubits/outcomes/outcomes_cubit.dart';

class OutComesPage extends StatefulWidget {
  const OutComesPage({super.key});

  @override
  State<OutComesPage> createState() => _OutComesPageState();
}

class _OutComesPageState extends State<OutComesPage> {
  // Declare TextEditingControllers
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // Helper method to calculate total
  int _calculateTotal(List<int> prices) {
    return prices.fold(0, (sum, price) => sum + price);
  }

  @override
  void initState() {
    context.read<OutcomesCubit>().getOutcomes();
    super.initState();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OutcomesCubit, OutcomesState>(
      listener: (context, state) {
        if (state is ErrorAddOutcomes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Error adding outcome"),
              backgroundColor: Colors.red,
            ),
          );
          print(state.message);
        }
        if (state is SuccessAddOutcomes) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Successfully added outcome"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close the dialog
          _priceController.clear();
          _noteController.clear();
          context.read<OutcomesCubit>().getOutcomes();
        }
        if (state is ErrorGetOutcomes) {
          print(state.message);
        }
        if (state is SuccessDeleteOutcome) {
          context.read<OutcomesCubit>().getOutcomes();
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.bgCard,
          appBar: AppBar(
            backgroundColor: AppColors.bgDark,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text("Out Comes", style: AppTexts.smallHeading),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: IconButton(
                  onPressed: () {
                    // Get the cubit BEFORE showing dialog
                    final outcomesCubit = context.read<OutcomesCubit>();

                    showDialog(
                      context: context,
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: AlertDialog(
                          backgroundColor: Colors.white,
                          title: const Text("Add out comes"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: _priceController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "price",
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _noteController,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "note",
                                ),
                              ),
                              const SizedBox(height: 20),
                              MaterialButton(
                                minWidth: 200,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                onPressed: () {
                                  if (_priceController.text.isEmpty ||
                                      _noteController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please fill all fields"),
                                      ),
                                    );
                                    return;
                                  }

                                  final price =
                                      int.tryParse(_priceController.text) ?? 0;
                                  final note = _noteController.text;

                                  // Use the cubit reference we captured earlier
                                  outcomesCubit.addOutcomesFunc(
                                    note: note,
                                    price: price,
                                  );
                                },
                                color: AppColors.primaryBlue,
                                child: Text(
                                  state is LoadingAddOutcomes
                                      ? "Adding..."
                                      : "Add",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          body: state is LoadingGetOutcomes
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 100,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ADDED: Total price display
                      if (state is SuccessGetOutcomes &&
                          state.data.isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: AppColors.primaryBlue,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "\$${_calculateTotal(state.data.map((e) => e.price).toList())}",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (state is SuccessGetOutcomes) ...[
                        Expanded(
                          child: ListView.separated(
                            scrollDirection: Axis.vertical,
                            itemBuilder: (context, index) {
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: AppColors.bgDark,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              state.data[index].price
                                                  .toString(),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              state.data[index].note,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 20),
                                  InkWell(
                                    onTap: () {
                                      context
                                          .read<OutcomesCubit>()
                                          .deleteOutcome(state.data[index].id);
                                    },
                                    child: Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemCount: state.data.length,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
        );
      },
    );
  }
}
