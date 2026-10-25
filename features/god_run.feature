Feature: A GOD PUMP run  (#37, docs/GOD_PUMP_PLAN.md)
  As a player, I want each night to choose between investing in the shop and calling the fuel truck
  so that the run builds tension and choices (serves: Advancement, Mastery).

  Scenario: The tank starts full and drains over days
    Given a new run
    Then the tank is full
    When a day uses $150 of gas
    Then the tank holds $150 less

  Scenario: The fuel truck is the bill
    Given a half-empty tank and enough cash
    When I call the truck
    Then it fills the tank for the wholesale price of the missing gas
    And the gas price rises 12% for the next delivery
    And I choose 1 of 3 cards

  Scenario: The gas tank and the delivery  (round 8)
    Given the night screen
    Then the GAS TANK panel shows an industrial tank whose sight glass and dial show the gas left
    When I call the truck
    Then the tanker rolls in, its hose fills the tank, the price per litre ticks up, and it leaves
    And then I choose my card (a click skips the animation)

  Scenario: Bankrupt
    Given an empty tank and too little cash for a delivery
    Then the run is over

  Scenario: The fight for the village  (round 10 B, replaces day 50)
    Given a new run
    Then my market share and my reputation start at 50%
    When a day ends
    Then my reputation moves by the day's fills (Topped off, Perfect and Good raise it; Overfilled and Unserved lower it)
    And Gaétan's specials take a little back
    And my market share moves toward my reputation, by at most a few points a night
    When my market share reaches 100%
    Then the run is won: the ending plays (Dad is avenged)
    When my market share falls to 0%
    Then the run is over: Gaétan has the whole village

  Scenario: The books  (round 10, playtest 9)
    When a day ends
    Then the report shows a P&L: sales, tips, gas sold at cost, spilled gas, drone gas, fines, net profit
    And a balance sheet: cash, gas in the tank at cost, equipment at cost, the cousin's loan, equity

  Scenario: Papa's Garage
    Given XP
    When I buy a nozzle, a bling and a perk
    Then they apply to every run
    And they are saved

  Scenario: No dead end when I forget the truck  (playtest 7)
    Given the tank won't last tomorrow
    Then the night shows a red warning to call the truck
    And buying an upgrade that leaves too little for the truck asks me to click again
    When I can't afford a full delivery but have at least $20
    Then the truck brings as much gas as my cash buys
    And a partial delivery under half a tank deals no cards
    And the run is only over when the tank is dry and I have under $20

  Scenario: 100% needs hours of Papa's Garage  (playtest 7, round 10 B)
    Given a fresh save
    Then the gas price climbs 25% a delivery and runs go broke before 100%
    When I own the supplier's contract (prices rise 20% slower a tier)
    And premium gas (every sale pays 10% more a tier)
    Then 100% is within reach (balance bot: a first win around 3 to 4 h)

  Scenario: Bonhomme gonflable, the tube man  (round 8, Papa's Garage perk)
    Given the tube man perk at tier 1
    When a car drives by on the road
    Then the tube man grabs it, sucks the gas out of it and spits it into my tank
    And puts it back on the road
    Given tier 2
    Then he drops the emptied car on my lot instead, as a customer
    And the tube man dances on the lot whenever I own him

  Scenario: Every Garage perk shows on the lot  (round 8)
    Given I own a perk in Papa's Garage
    Then its prop is on the lot every day of every run

  Scenario: Bling on the nozzle  (round 8)
    Given I own bling in Papa's Garage
    Then every piece I own is a gold ring or bracelet on the nozzle's handle
    And every piece I've equipped shows on the nozzle as itself
    And the dangling ones (dice, pine, medal, rabbit's foot) swing when I move the nozzle

  Scenario: The lore drives in  (round 9: replaces the morning paper)
    Given a day when someone visits (Gaétan, Papa, Sylvie, Me Tremblay, cousin Réjean, the curé)
    Then their car pulls in and parks in the lot's corner by the store
    And they chat with the regulars in small wordless bubbles, then drive off
    And the day report shows what they said (OVERHEARD TODAY), with a line from Dad about the market share

  Scenario: The story so far, on the menu screen  (round 8)
    Then the title screen shows my lifetime numbers
    And a scrapbook: the market share each run ended at, and the last thing overheard

  Scenario: The run's last front page  (round 8)
    When a run ends
    Then a special edition tells it, with my cash day by day and the price per delivery
