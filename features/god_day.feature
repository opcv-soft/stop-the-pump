Feature: A GOD PUMP day  (#37, docs/GOD_PUMP_PLAN.md)
  As a player, I want everything I own to shape the day, and a cast of cars that each play differently
  so that every run feels different (serves: Mastery, Advancement, Comedy).

  Scenario: The clock limits the day
    Given the store closes at 13 h
    Then the day lasts 27 seconds
    And the clock reads 7 h at the start

  Scenario: Marketing queues cars at opening
    Given 3 cars of queue
    When the day opens
    Then 3 customers are already waiting in the lot

  Scenario: Auto-aim bends the stream
    Given auto-aim
    When I pour just beside a car
    Then the car fills

  Scenario: Drone nozzles fill cars on their own
    Given a drone nozzle and a waiting car
    When time passes
    Then the drone fills and settles the car

  Scenario Outline: Car types
    Given a <car>
    Then <rule>
    Examples:
      | car      | rule                                          |
      | pickup   | it pays 80% of its sale                       |
      | bazou    | its tank takes fuel slower                    |
      | thief    | it siphons gas from customers; pouring scares it |
      | electric | pouring on it costs a $10 fine                |
      | sweeper  | it cleans the puddles it drives over          |
      | clumsy   | cars it bumps spill some of their gas         |

  Scenario: Patience
    Given a car left waiting past its patience
    Then it drives off and counts as unserved

  Scenario: The day report  (playtest 8: Misses split in two)
    When the day ends
    Then the report has loot, gas left, XP, cars, grades, accuracy and best combo
    And the grades are Super, Perfect, Good, OK, Overfilled and Unserved
    And a car that left under 80% (patience or closing) is Unserved: it isn't a car fueled,
      doesn't count against accuracy and earns no XP

  Scenario: The regulars live on the lot  (round 8)
    Given the gaz bar is open
    Then Ti-Guy, Mme Gagnon, Bertrand and Le Grand spend time on the bench
    And get up to watch me pour from beside the store (playtest 9: off the play area), go inside for a coffee and come back out with it,
      or (Le Grand) step out for a smoke
    And two at most are away from the bench at once
    And wherever they are, they throw their arms up for a top-off and applaud a Perfect

  # --- Round 10, batch A (playtest 9: focus) ---------------------------------------------------

  Scenario: The nozzle ring shows the reach
    Given the nozzle is aimed at the lot
    Then a ring on the ground shows the area the nozzle covers
    And with no car in the ring the gas spills
    And with one car in the ring that car fills

  Scenario: Double jet fills two cars in the ring, each at full speed
    Given Double jet and two cars inside the ring
    When I pour for one second
    Then both cars get a full second of flow
    And when I release, both cars are graded and paid

  Scenario: Cars stay in front of the money
    When a car pays
    Then coins pop out of it and fly straight into the tray
    And no money rests on the lot

  Scenario: Coins in poker stacks
    When a car pays $27
    Then the tray gets one red $20, one green $5 and two blue $1 coins
    And at closing the stacks slide into the cash register before the report opens

  Scenario: The day bar
    Then a bar across the top runs from the opening hour to the closing hour

  Scenario: The regulars step aside
    Then the regulars never speak in bubbles
    And they keep to the store's side of the lot
    And they still cheer a top-off and applaud a Perfect
    And a visitor parks in the corner by the store and chats without words

  Scenario: Drones burn gas
    Given a drone nozzle
    When it flies for a second
    Then the tank loses the drone's gas

  Scenario: XP is litres × combo points × accuracy
    Given I put 30 L in cars with combo points 6 at 90% accuracy
    Then the day earns 30 × 6 × 0.9 = 162 XP

  # --- Round 10, batch B: the rival across the road --------------------------------------------

  Scenario: The avenue is shared with Gaétan
    Given cars drive along the avenue both ways
    Then a car that wants gas shows a low fuel gauge
    And it picks my gaz bar or Gaétan's by my market share
    When it picks Gaétan
    Then it pulls into his station across the road, waits by a pump and drives on with a full gauge

  Scenario: Reputation from the day's fills
    When cars are graded
    Then the day counts reputation: Topped off +2, Perfect +1.25, Good +0.6, OK 0, Overfilled -0.75, Unserved -0.5
