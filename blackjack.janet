(def rng (math/rng (os/time)))

(def cards [2 3 4 5 6 7 8 9 10 "J" "Q" "K" "A"])

# TODO: fix crash on empty shoe!

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
  (update-in state [:hands who] |(array/push $ (array/pop (state :shoe)))))

(defn hit [state]
  (deal state :player))

(defn stand [state]
  (put state :stand true))

(defn double [state]
  (let [amount (get state :bet)]
    (put state :stand true)
    (update state :bet |(* 2 $))))

(defn player-move [state]
  # TODO: add splitting
  (print "(h)it (s)tand (d)ouble")
  (case (string/trim (get-player-input))
    "h" (hit state)
    "s" (stand state)
    "d" (double state)
    (player-move state)))

(defn get-bet! [state]
  (print-bank state)
  (print)
  (print "How much do you want to bet?")
  (let [bet (scan-number (get-player-input))]
    (if bet
      (do
        (update state :bet |(+ $ bet)))
      (do
        (print "Please enter a number")
        (get-bet! state)))))

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

# TODO: blackjack pays 3 to 2
(defn finish-hand [state]
  (print (end-message-for (check-win-conditions state)))

  (let [bet (get state :bet)
        [op msg] (if (player-wins? state) [+ "+"] [- "-"])]
    (print msg "$" bet)
    (update state :bank |(op $ bet)))
  (print)
  (reset-hand state))

(defn main [& args]
  (let [state (table/clone initial-state)]
    (forever 
      (play-hand state)
      (finish-hand state)))
    0)

(main)
