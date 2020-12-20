# Blackjack

A Blackjack implementation written in [Janet](https://janet-lang.org/). Runs in the command line.

## Install

1. Install Janet per the [instructions](https://janet-lang.org/docs/index.html).
2. Clone this repo
3. Run `jpm deps` to install dependencies to your Janet path
4. Run `janet blackjack.janet` to run in interpreted mode

## Build

Run `jpm build` to build the binary. You can run it, install it to your Janet bin path with `jpm install`, and copy it wherever you like otherwise (e.g. `/usr/local/bin`).

## Notes

Cancel on any prompt with `Ctrl-C`.

Dealer stands on soft 17 and Blackjack pays 3-to-2.

You can set autobetting if you don't care about entering a wager amount every hand. When asked for your betting amount, type `autobet 5` to set $5 as the automatic betting amount. You can later cancel your autobet by typing `c` when asked for your move.

Flags are explained by running with `--help`.

## Known issues

1. Splitting is currently not implemented.
2. Can only double once per hand

## Nice to have features

1. Configure Blackjack payout
2. Configure money amount
3. Configure if dealer hits on soft 17
4. Insurance
5. Count number of hands played
6. Feedback on Basic Strategy
7. More concise view
