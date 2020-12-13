(def rng (math/rng (os/time)))

(def cards [2 3 4 5 6 7 8 9 10 "J" "Q" "K" "A"])

(defn card-value [card mode]
  (cond 
    (= card "A") (if (= mode :hard) 11 1)
    (= (type card) :string) 10
    card))

(defn sum-hand-mode [hand mode]
  (->> hand
       (map |(card-value $ mode))
       sum))

(defn sum-hand [hand]
  (let [hard-sum (sum-hand-mode hand :hard)]
    (if (> hard-sum 21)
      (sum-hand-mode hand :soft)
      hard-sum)))

(defn shuffle [array]
  (let [shuffled-array @[]]
    (each item array
      (array/insert shuffled-array
                    (dec (math/rng-int rng (length shuffled-array)))
                    item))
    shuffled-array))

(defn generate-decks [n]
  (let [deck @[]]
    (repeat (* n 4) (array/concat deck cards))
    (shuffle deck)))

(def initial-state
  @{:bank 200
    :bet 0
    :shoe (generate-decks 1)
    :stand false
    :autobet nil
    :hands @{:player @[]
             :dealer @[]}})

(defn bust? [state who]
  (> (sum-hand (get-in state [:hands who])) 21))

(defn blackjack? [state who]
  (let [hand (get-in state [:hands who])]
    (and
      (= (sum-hand hand) 21)
      (= (length hand) 2))))

(defn check-end-conditions [state]
  (cond
    (bust? state :player) :player-bust
    (bust? state :dealer) :dealer-bust
    (blackjack? state :player) :player-blackjack
    (blackjack? state :dealer) :dealer-blackjack
    false))

(defn hand-over? [state]
  (truthy? (check-end-conditions state)))

(defn player-hand [state]
  (get-in state [:hands :player]))

(defn dealer-hand [state]
  (get-in state [:hands :dealer]))

(defn format-player-hand [state]
  (string/join (map string (player-hand state)) " "))

(defn format-dealer-hand [state]
  (if
    (or (hand-over? state)
        (get state :stand))
    (string/join (map string (dealer-hand state)) " ")
    (string (first (dealer-hand state)) " _")))

(defn print-bank [state]
  (print "Bank:   $" (state :bank)))

(defn print-hand [state]
  (print "Bet:    $" (state :bet))
  (print "You:    " (format-player-hand state) " (" (sum-hand (player-hand state))")")
  (print "Dealer: " (format-dealer-hand state) " (" (sum-hand (dealer-hand state)) ")")
  (print "Cards:  " (length (get state :shoe)))
  (print))

(defn get-player-input []
  (let [input (string/trim (getline "> "))]
    (if
      (or
        (= input "cancel")
        (= input ""))
      (os/exit 1))
    (print)
    input))

(defn deal [state who]
  (update-in state [:hands who] |(array/push $ (array/pop (state :shoe))))
  (if (empty? (state :shoe))
    (do
      (print "Shuffling cards..\n")
      (put state :shoe (generate-decks 1)))))

(defn hit [state]
  (deal state :player))

(defn stand [state]
  (put state :stand true))

(defn double [state]
  (let [amount (get state :bet)]
    (put state :stand true)
    (update state :bet |(* 2 $))))

(defn player-move [state]
  (if (get state :autobet)
    (print "(h)it (s)tand (d)ouble - (c)ancel autobet (starting next hand)")
    (print "(h)it (s)tand (d)ouble"))

  # TODO: add splitting
  (case (string/trim (get-player-input))
    "h" (hit state)
    "s" (stand state)
    "d" (double state)
    "c" (do
          (put state :autobet nil)
          (player-move state))
    (player-move state)))

(defn validate-bet [input state]
  (let [amount (scan-number input)]
    (if
      (and
        (> amount 0)
        (int? amount)
        (>= (get state :bank) amount))
      amount)))

(defn get-bet! [state]
  (print-bank state)
  (print)
  (if (get state :autobet)
    (let [bet (get state :autobet)]
      (do
        (print "Autobetting $" bet "\n")
        (update state :bet |(+ $ bet))))
    (do
      (print "How much do you want to bet? (type `autobet <amount>` to set autobetting)")
      (let [input (get-player-input)]
        (if (string/has-prefix? "autobet" input)
          (let [bet (validate-bet (get (string/split " " input) 1) state)]
            (if bet
              (do
                (put state :autobet bet)
                (update state :bet |(+ $ bet)))
              (get-bet! state)))
          (let [bet (validate-bet input state)]
            (if bet
              (do
                (update state :bet |(+ $ bet)))
              (do
                (print "Please enter a positive integer that you can actually afford")
                (get-bet! state)))))))))

(defn end-message-for [condition]
  (case condition
    :player-bust "You bust!"
    :dealer-bust "Dealer busts!"
    :player-blackjack "Blackjack!"
    :dealer-blackjack "Dealer Blackjack!"
    :player-wins "You win!"
    :player-loses "You lose!"
    :push "Push!"))

(defn player-turn [state]
  (forever
    (player-move state)
    (print-hand state)
    (if
      (or
        (get state :stand)
        (hand-over? state))
      (break))))

(defn dealer-turn [state]
  (while (< (sum-hand (get-in state [:hands :dealer])) 17)
    (deal state :dealer)
    (print-hand state)))

(defn deal-initial-cards [state]
  (repeat 2
          (deal state :player)
          (deal state :dealer)))

(defn game-over? [state]
  (<= (state :bank) 0))

(defn play-hand [state]
  (get-bet! state)
  (deal-initial-cards state)
  (print-hand state)
  (if (not (hand-over? state))
    (player-turn state))
  (if (not (hand-over? state))
    (dealer-turn state)))

(defn player-wins? [state]
  (or
    (let [end-condition (check-end-conditions state)]
      (or
        (= end-condition :dealer-bust)
        (= end-condition :player-blackjack)))
    (and
      (get state :stand)
      (>
       (sum-hand (player-hand state))
       (sum-hand (dealer-hand state))))))

(defn check-win-conditions [state]
  (or
    (check-end-conditions state)
    (let [player-count (sum-hand (player-hand state))
          dealer-count (sum-hand (dealer-hand state))]
      (cond
        (> dealer-count player-count) :player-loses
        (< dealer-count player-count) :player-wins
        (= dealer-count player-count) :push))))

(defn reset-hand [state]
  (put state :bet 0)
  (put state :stand false)
  (put-in state [:hands :player] @[])
  (put-in state [:hands :dealer] @[]))

(defn bank-win [state]
  (let [bet (get state :bet)]
    (if (= (check-end-conditions state) :player-blackjack)
      (do
        (let [increased-bet (* 1.5 bet)]
          (print "+$" increased-bet " - Blackjack pays 3-to-2")
          (update state :bank |(+ $ increased-bet))))
      (do
        (print "+$" bet)
        (update state :bank |(+ $ bet))))))

(defn bank-lose [state]
  (let [bet (get state :bet)]
    (print "-$" bet)
    (update state :bank |(- $ bet))))

(defn finish-hand [state]
  (let [end-state (check-win-conditions state)]
    (print (end-message-for end-state))
    (cond
      (= end-state :push) :nothing
      (player-wins? state) (bank-win state)
      (bank-lose state)))
  (print)
  (reset-hand state))

(defn bankrupt? [state]
  (<= (get state :bank) 0))

(defn main [& args]
  (let [state (table/clone initial-state)]
    (while (not (bankrupt? state))
      (play-hand state)
      (finish-hand state))
    (print "You're out of money. Please play again soon.")
    0))
