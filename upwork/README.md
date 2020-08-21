Upwork CSV parser
=======

Sample usage:

` upwork.statement.analyze ~/bel.ip/upwork/statements/statements_2020-07-01_2020-07-31.csv`

Output:

```
earnings          831.92
expenses          122.83
profit            709.09
expenses.%        14.764640831 %
withdrawn         1612.14
```

- Earnings :  all income ( gross )
- expenses :   Upwork fees & buying connects
- profit:   Earnings minus expenses
- expenses.% : expenses % Earnings
- withdrawn:    amount of money withdrawn


