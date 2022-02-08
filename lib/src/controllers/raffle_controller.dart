import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:raffle_local/src/models/raffle_details.dart';
import 'package:raffle_local/src/models/raffle_num.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

class RaffleController extends ControllerMVC {
  RaffleDetails raffleDetails = RaffleDetails();
  String _buyer = "";

  int min = 1;

  bool selling = true;
  bool finished = false;
  bool loadingRaffleNums = true;

  static const raffleTime = Duration(seconds: 10);

  List<RaffleNum> raffleNums = [];
  List<RaffleNum> raffleBuyingNums = [];
  List<RaffleNum> raffleSoldNums = [];
  Map<String, dynamic> winner = {};

  int sorteado = 0;
  int sellingNums = 0;
  int freeNums = 0;
  double total = 0.0;

  double liquidEarning = 0.0;

  //Creates the raffle
  void createRaffle(context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Criar rifa",
          ),
          content: Form(
            child: Column(
              children: [
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      raffleDetails.premiumDescription = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Descrição do premio",
                    hintText: "Insira aqui a descrição do premio",
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      raffleDetails.premiumValue = double.parse(value);
                    });
                  },
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    labelText: "Valor do premio",
                    hintText: "Insira aqui o valor do premio",
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      raffleDetails.max = int.parse(value);
                    });
                  },
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    labelText: "Quantidade de cotas",
                    hintText: "Informe o máximo de cotas da rifa",
                  ),
                ),
                TextFormField(
                  onChanged: (value) {
                    setState(() {
                      raffleDetails.quotaValue = double.parse(value);
                    });
                  },
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(
                    labelText: "Valor de venda cota",
                    hintText: "Informe o valor de venda da cota",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                saveRaffleDetails().then((value) {
                  setState(() {
                    sellingNums = 0;
                    freeNums = 0;
                    sorteado = 0;
                    finished = false;
                  });
                  for (var i = min; i <= raffleDetails.max; i++) {
                    RaffleNum value = RaffleNum(
                      index: i - 1,
                      number: i,
                      buyer: "",
                    );
                    raffleNums.add(value);
                    sellingNums++;
                    setState(() {});
                  }
                  setState(() {
                    freeNums = sellingNums;
                  });
                  Navigator.of(context).pop();
                });
              },
              child: Text("Confirm"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            )
          ],
        );
      },
    );
  }

  //Saves the raffle details
  Future<void> saveRaffleDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('raffleDetails', jsonEncode(raffleDetails));
  }

  Future<void> getRaffleDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var getDetails = prefs.getString('raffleDetails');
    RaffleDetails _details = jsonDecode(getDetails!);
    setState(() {
      raffleDetails = _details;
    });
  }

  //Saves all the raffle numbers into the shared preferences
  Future<void> saveRaffleNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('raffleNums', jsonEncode(raffleNums));
  }

  //Saves all the sold numbers into the shared preferences
  Future<void> saveraffleSoldNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('raffleSoldNums', jsonEncode(raffleSoldNums));
  }

  //Clears all the raffle info from shared preferences
  Future<void> clearInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('raffleNums');
    await prefs.remove('raffleSoldNums');
  }

  //Get the saved numbers from sharedpreferences
  Future<void> getRaffleNums() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('raffleNums')) {
      var getRaffleNums = prefs.getString('raffleNums');
      List<RaffleNum> list = (jsonDecode(getRaffleNums!) as List)
          .map((data) => RaffleNum.fromJSON(data))
          .toList();
      setState(() {
        raffleNums = list;
      });
    }
    if (prefs.containsKey('raffleSoldNums')) {
      var getraffleSoldNums = prefs.getString('raffleSoldNums');
      List<RaffleNum> list = (jsonDecode(getraffleSoldNums!) as List)
          .map((data) => RaffleNum.fromJSON(data))
          .toList();
      setState(() {
        raffleSoldNums = list;
      });
    }
    print("read");
  }

  //Function buying a raffle number
  void buyingRaffleNum(RaffleNum number) {
    raffleBuyingNums.add(number);
    raffleNums.removeWhere((num) => num.number == number.number);

    total += raffleDetails.quotaValue;
    setState(() {});
  }

  //Select all remaining numbers to sell
  void sellAllRaffleNumbers() {
    raffleNums.forEach((num) {
      raffleBuyingNums.add(num);
      total += raffleDetails.quotaValue;
      setState(() {});
    });
    setState(() {
      raffleNums.clear();
    });
  }

  //Confirms the selling
  void confirmSelling() {
    raffleBuyingNums.forEach((num) {
      num.buyer = _buyer;
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
        selling = true;
      });
    } else {
      setState(() {
        total = 0;
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
      sorteado = Random().nextInt(raffleDetails.max);
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
                        Text("Premio: ${raffleDetails.premiumDescription}"),
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
      total += raffleDetails.quotaValue;
      setState(() {});
    });

    liquidEarning = total - raffleDetails.premiumValue;
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Valor do premio"),
                    Text(
                      "R\$ ${raffleDetails.premiumValue}",
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Vendido"),
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
                          Text("Ganho"),
                          Text(
                            "R\$ $liquidEarning",
                            style: TextStyle(
                              color:
                                  liquidEarning < 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Ganho"),
                          Text(
                            "R\$ $total",
                            style: TextStyle(
                              color: Colors.green,
                            ),
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

  //Shows an alert with all the selling numbers
  void showSellingNumbers(context) {
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
              height: 250,
              width: 100,
              child: Form(
                child: Column(
                  children: [
                    Container(
                      height: 148,
                      width: 400,
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
                    TextFormField(
                      onChanged: (value) {
                        setState(() {
                          _buyer = value;
                        });
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Por favor informe o comprador";
                        }
                        return null;
                      },
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  confirmSelling();
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Confirmar",
                  style: TextStyle(
                    color: Colors.green,
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
                  "Cancelar",
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
