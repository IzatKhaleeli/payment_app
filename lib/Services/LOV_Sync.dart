  import 'dart:convert';

import 'package:flutter/material.dart';
  import '../Models/Bank.dart';
  import '../Models/Currency.dart';
  import 'LOV_Services.dart';
  import 'database.dart';


  class LOVCompareService {
    // Compare and sync currencies
    static Future<void> compareAndSyncCurrencies() async {
      try {
        // Fetch remote currencies
        List<Currency> remoteCurrencies = await LovApiService.fetchCurrencies();

        // Convert remote currencies to a list of maps
        List<Map<String, dynamic>> remoteCurrenciesData = remoteCurrencies.map((currency) => currency.toMap()).toList();

        // Clear local currencies
         await DatabaseProvider.clearAllCurrencies();

        for (var remoteData in remoteCurrenciesData) {
          await DatabaseProvider.insertCurrency(remoteData);
          List<Map<String, dynamic>> currencies = await DatabaseProvider.getAllCurrencies();
          for (var currency in currencies) {
            print('Currency{id: ${currency['id']}, arabicName: ${currency['arabicName']}, englishName: ${currency['englishName']}}');
          }
        }
      } catch (e) {
        print('Error comparing and syncing currencies: $e');
      }
    }

    // Compare and sync banks
    static Future<void> compareAndSyncBanks() async {
      try {
        // Fetch remote banks
        List<Bank> remoteBanks = await LovApiService.fetchBanks();

        // Convert remote banks to a list of maps
        List<Map<String, dynamic>> remoteBanksData = remoteBanks.map((bank) => bank.toMap()).toList();

        // Clear local banks
        await DatabaseProvider.clearAllBanks();

        // Insert remote banks into local database
        for (var remoteData in remoteBanksData) {
          await DatabaseProvider.insertBank(remoteData);
          // Optionally print the inserted bank
        }


      } catch (e) {
        print('Error comparing and syncing banks: $e');
      }
    }
  }
