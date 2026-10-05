
| State | Source | Consumer | Direction | Mechanism |
|---|---|---|---|---|
| email recipients (list of strings) | This modal (seeded once from the email seed at mount) | Email recipient list (read-only), Send payload | Down only | Component state, seeded from inputs |
| sms recipients (list of strings) | This modal (seeded once from the phone seed at mount) | SMS recipient list (read-only), Send payload | Down only | Component state, seeded from inputs |
| email note / sms note | This modal | Section note fields, Send payload | Down / Up | Component state |
| discard-confirm open | This modal | The discard-confirmation alert | Down | Boolean state |
| busy | Caller | Send + dismissal guard + spinner | Down | Input |
| open | Caller | Dialog | Down | Input; close notification up |

