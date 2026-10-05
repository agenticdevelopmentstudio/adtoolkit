
A running total kept per currency: hundredths in each ISO-4217 code, never converted, never mixed. The money type's sum refuses mixed currencies and the formatter formats one currency, so anything that totals amounts across clients billed in different currencies needs this bucket. The wording of the result is each currency formatted on its own, in code order, joined with a plus sign, such as `€40.00 + $250.00` (`EUR` sorts before `USD`).

