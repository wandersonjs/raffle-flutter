import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:raffle_local/src/models/raffle.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

class RaffleController extends ControllerMVC {
  String premiumDescription = "Fiat uno mille 2008"; //
  double premiumValue = 3500.0;
  int min = 1;
  int max = 3000;
  double quotaValue = 15.0;

  bool selling = true;
  bool finished = false;
  bool loadingRaffleNums = true;

  static const raffleTime = Duration(seconds: 10);

  List<Raffle> raffleNums = [];
  List<Raffle> raffleBuyingNums = [];
  List<Raffle> raffleSoldNums = [];
  Map<String, dynamic> winner = {};

  int sorteado = 0;
  int sellingNums = 0;
  int freeNums = 0;
  double total = 0.0;

  double liquidEarning = 0.0;
  double adminEarning = 0.0;
  double donatorEarning = 0.0;
  double sponsorEarning = 0.0;
  double bankEarning = 0.0;

  double adminPercentage = 0.20;
  double donatorPercentage = 0.50;
  double sponsorPercentage = 0.30;
  double bankPercentage = 0.03;
  double bankFixValue = 0.40;

  List<String> buyer = [
    'Wanderson',
    'Julia',
    'Tereza',
    'Maria',
    'Benedito',
    'Geraldo',
    'Antonio',
    'Suzanny',
    'Camila',
    'Catarina',
  ];

  //Creates the raffle
  void createRaffle(context) {
    sellingNums = 0;
    freeNums = 0;
    sorteado = 0;
    finished = false;
    setState(() {});
    for (var i = min; i <= max; i++) {
      Raffle value = Raffle(
        index: i - 1,
        number: i,
        buyer: "",
        sponsor: "",
      );
      raffleNums.add(value);
      sellingNums++;
      setState(() {});
    }
    setState(() {
      freeNums = sellingNums;
    });
  }

  //Saves all the raffle numbers into the shared preferences
  Future<void> saveRaffleNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('raffleNums', jsonEncode(raffleNums));
  }

  //Clears all the raffle info from shared preferences
  Future<void> clearInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('raffleNums');
    await prefs.remove('raffleSoldNums');
  }

  //Saves all the sold numbers into the shared preferences
  Future<void> saveraffleSoldNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('raffleSoldNums', jsonEncode(raffleSoldNums));
  }

  //Get the saved numbers from sharedpreferences
  Future<void> getRaffleNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('raffleNums')) {
      var getRaffleNums = prefs.getString('raffleNums');
      List<Raffle> list = (jsonDecode(getRaffleNums!) as List)
          .map((data) => Raffle.fromJSON(data))
          .toList();
      setState(() {
        raffleNums = list;
      });
    }
    if (prefs.containsKey('raffleSoldNums')) {
      var getraffleSoldNums = prefs.getString('raffleSoldNums');
      List<Raffle> list = (jsonDecode(getraffleSoldNums!) as List)
          .map((data) => Raffle.fromJSON(data))
          .toList();
      setState(() {
        raffleSoldNums = list;
      });
    }
    print("read");
  }

  //Function buying a raffle number
  void buyingRaffleNum(Raffle number) {
    number.buyer = buyer[Random().nextInt(buyer.length)];
    raffleBuyingNums.add(number);
    raffleNums.removeWhere((num) => num.number == number.number);

    total += quotaValue;
    setState(() {});
  }

  //Select all remaining numbers to sell
  void sellAllRaffleNumbers() {
    raffleNums.forEach((num) {
      num.buyer = buyer[Random().nextInt(buyer.length)];
      raffleBuyingNums.add(num);
      total += quotaValue;
      setState(() {});
    });
    setState(() {
      raffleNums.clear();
    });
  }

  //Confirms the selling
  void confirmSelling() {
    raffleBuyingNums.forEach((num) {
      raffleSoldNums.add(num);
    });
    freeNums = raffleNums.length - raffleBuyingNums.length;
    setState(() {});
    clearValues();
    print(raffleSoldNums.length);
    saveRaffleNums().then((value) {
      print("Números de rifa salvos com sucesso!");
    });
    saveraffleSoldNums().then((value) {
      print("Numeros comprados de rifa salvos com sucesso!");
    });
    raffleBuyingNums.clear();
  }

  //cancell the selling number runing every one and reinserting on raffleNums
  void cancelSelling() {
    for (var i = 0; i < raffleBuyingNums.length; i++) {
      raffleNums.insert(i, raffleBuyingNums[i]);
    }

    setState(() {});
    clearValues();
    print(raffleBuyingNums.length);
    raffleBuyingNums.clear();
  }

  //Clears all the values after the raffle
  void clearValues() {
    if (finished) {
      setState(() {
        raffleSoldNums.clear();
        raffleNums.clear();
        winner.clear();
        total = 0;
        donatorEarning = 0;
        adminEarning = 0;
        sponsorEarning = 0;
        bankEarning = 0;
        selling = true;
      });
    } else {
      setState(() {
        total = 0;
        donatorEarning = 0;
        adminEarning = 0;
        sponsorEarning = 0;
        bankEarning = 0;
        selling = true;
      });
    }
  }

  void raffle(context) {
    //Verifies if the sold nums size are bigger than zero, if so the raffle runs, else shows an alert saying that no numbers where sold
    if (raffleSoldNums.length > 0) {
      Timer sort = Timer(raffleTime, () {
        Navigator.of(context, rootNavigator: true).pop();
      });
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Sorteando"),
            content: CircularProgressIndicator(),
          );
        },
      ).then((value) {
        sort.cancel();
      });
      donatorEarning = double.parse(donatorEarning.toStringAsFixed(2));
      adminEarning = double.parse(adminEarning.toStringAsFixed(2));
      sponsorEarning = double.parse(sponsorEarning.toStringAsFixed(2));
      bankEarning = double.parse(bankEarning.toStringAsFixed(2));
      sorteado = Random().nextInt(max);
      Timer.periodic(
        raffleTime,
        (timer) {
          DateTime agora = DateTime.now();
          setState(() {
            finished = true;
          });
          raffleSoldNums.forEach((num) {
            if (num.number == sorteado) {
              setState(() {
                winner = {
                  "number": num.number,
                  "buyer": num.buyer,
                  "sponsor": num.sponsor
                };
              });
            }
          });
          if (winner.isNotEmpty) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Nº sorteado: ${winner['number']}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  content: Container(
                    height: 100,
                    child: Column(
                      children: [
                        Text(
                          "Ganhador e ${winner['buyer']}",
                        ),
                        Text("Premio: $premiumDescription"),
                        Text("Patrocionador ${winner['sponsor']}"),
                        Text("$agora")
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        getEarnigs(context);
                        timer.cancel();
                      },
                      child: Text("OK"),
                    )
                  ],
                );
              },
            );
            timer.cancel();
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(
                    "Nº sorteado: $sorteado",
                  ),
                  content: Text(
                    "Infelizmente não tivemos nenhuma ganhador desta vez",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        getEarnigs(context);
                        timer.cancel();
                      },
                      child: Text("OK"),
                    )
                  ],
                );
              },
            );
            timer.cancel();
          }
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(
              "Não houve vendas",
            ),
            content: Text(
              "Ainda não foram vendidos números para esta rifa",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              )
            ],
          );
        },
      );
    }
  }

  void getTotalEarnings() {
    raffleSoldNums.forEach((element) {
      total += quotaValue;
      bankEarning += ((quotaValue * bankPercentage) + bankFixValue);
      setState(() {});
    });

    liquidEarning = total - bankEarning;
    donatorEarning = liquidEarning * donatorPercentage;
    adminEarning = liquidEarning * adminPercentage;
    sponsorEarning = liquidEarning * sponsorPercentage;
    donatorEarning = double.parse(donatorEarning.toStringAsFixed(2));
    adminEarning = double.parse(adminEarning.toStringAsFixed(2));
    sponsorEarning = double.parse(sponsorEarning.toStringAsFixed(2));
    bankEarning = double.parse(bankEarning.toStringAsFixed(2));
    setState(() {});
  }

  void getEarnigs(context) {
    getTotalEarnings();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Ganhos",
              ),
            ],
          ),
          content: Container(
            height: 100,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total da rifa"),
                    Text(
                      "R\$ $total",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                winner.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Doador"),
                          Text(
                            "R\$ ${donatorEarning - premiumValue}",
                            style: TextStyle(
                              color: (donatorEarning - premiumValue) < 0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Doador"),
                          Text(
                            "R\$ $donatorEarning",
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Patrocionadores"),
                    Text(
                      "R\$ $sponsorEarning",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Admin"),
                    Text(
                      "R\$ $adminEarning",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Banco"),
                    Text(
                      "R\$ $bankEarning",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                clearValues();
                if (finished) {
                  clearInfo().then((value) {
                    createRaffle(context);
                  });
                }
              },
              child: Text("Fechar"),
            )
          ],
        );
      },
    );
  }

  void showBuyingNumbers(context) {
    if (raffleBuyingNums.length >= 1 && total >= 0) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  height: 50,
                  width: 200,
                  padding: EdgeInsetsDirectional.all(5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: Colors.blue),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Cotas: ${raffleBuyingNums.length}"),
                    ],
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                Text("Total: R\$ $total"),
              ],
            ),
            content: Container(
              height: 200,
              width: 100,
              child: GridView.builder(
                itemCount: raffleBuyingNums.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Colors.amber,
                    ),
                    child: TextButton(
                      child: Container(
                        child: Center(
                          child: Text(
                            raffleBuyingNums[index].number.toString(),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      onPressed: () {},
                    ),
                  );
                },
              ),
            ),
            actions: [
              Container(
                child: TextButton(
                  onPressed: () {
                    confirmSelling();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Confirmar venda",
                    style: TextStyle(
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.plus_one_rounded),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                color: Colors.amber,
              ),
              TextButton(
                onPressed: () {
                  cancelSelling();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancelar venda",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Whoops"),
            content: Text("Você ainda não selecionou nenhum número"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }
}
