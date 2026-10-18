// =====================================================================
//  TEA SIM - story beats and CK3-style situations
//
//  Each event:
//    key, title, text, story (true = only fires when the story queues it)
//    path     focus path this event belongs to ("" = any). Events from your
//             active focus are 2.5x more likely to show up.
//    weight   how likely it is when a random event rolls
//    cooldown days before it can fire again
//    cond     function returning true when it is allowed to fire
//    options  [{ text, hint, cost (optional - greys out if you can't afford it), fn }]
// =====================================================================

// ---------- queue helpers ----------
function tea_find_event(_key) {
    for (var i = 0; i < array_length(global.events); i++) if (global.events[i].key == _key) return global.events[i];
    return undefined;
}

function tea_queue_event_by_key(_key) {
    var e = tea_find_event(_key);
    if (!is_undefined(e)) array_push(global.event_queue, e);
}

function tea_queue_message(_title, _text) {
    array_push(global.event_queue, {
        key: "msg", title: _title, text: _text, story: true,
        options: [ { text: "Continue", hint: "", fn: function() { } } ]
    });
}

function tea_open_next_event() {
    var e = global.event_queue[0];
    array_delete(global.event_queue, 0, 1);
    global.current_event = e;
    global.modal = "event";
    global.event_last[$ e.key] = global.day;
}

function tea_try_random_event() {
    var pool = [];
    var total = 0;
    for (var i = 0; i < array_length(global.events); i++) {
        var e = global.events[i];
        if (e.story) continue;
        if (variable_struct_exists(global.event_last, e.key) && global.day - global.event_last[$ e.key] < e.cooldown) continue;
        if (!e.cond()) continue;
        var w = e.weight;
        if (e.path != "" && e.path == global.focus) w *= 2.5;
        array_push(pool, [e, w]);
        total += w;
    }
    if (total <= 0) return;
    var r = random(total);
    for (var j = 0; j < array_length(pool); j++) {
        r -= pool[j][1];
        if (r <= 0) { array_push(global.event_queue, pool[j][0]); return; }
    }
    array_push(global.event_queue, pool[array_length(pool) - 1][0]);
}

function tea_schedule_group(_hours_from_now, _count, _tag, _label, _income) {
    var h = min(global.minute / 60 + _hours_from_now, TEA_CLOSE_HOUR - 1);
    array_push(global.scheduled, { hour: h, count: _count, tag: _tag, label: _label, income: _income });
}

function tea_run_inspection(_bonus) {
    var pts = 50 + _bonus + irandom(35);
    if (tea_staff_count("manager") > 0) pts += 20;
    if (tea_staff_count("back") > 0) pts += 5;
    pts += min(10, tea_ambience() / 3);
    pts -= global.today.angry * 3;
    if (pts >= 85) {
        tea_add_rep(4);
        tea_queue_message("A Glowing Report", "The inspector runs a finger along the top shelf, finds nothing, and actually smiles. 'Your father kept a clean shop too.' The certificate goes up by the register.\n\n+4 reputation");
    } else if (pts >= 65) {
        tea_add_rep(1);
        tea_queue_message("Passed", "A few notes about labeling the fridge, but you pass without trouble.\n\n+1 reputation");
    } else {
        global.money -= 300;
        tea_add_rep(-5);
        tea_queue_message("Failed Inspection", "Expired milk in the back fridge and a mop bucket in the wrong place. The fine is $300, and the yellow notice in the window is worse.\n\n-$300, -5 reputation. (A Manager makes inspections much easier.)");
    }
}


// ---------- the events themselves ----------
function tea_build_events() {
    return [

        // ================= STORY =================
        {
            key: "intro", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: TEA_SHOP_NAME,
            text: "The bell over the door still rings the way it did when you were small. Your father ran this little tea shop on Main Street for thirty years, and now, after the funeral and the paperwork, it's yours.\n\n$2,000 in the account. A register that sticks. A town that still remembers his chai.\n\nHe never wanted it to be famous. He wanted it to be enough. Grow it until you're content.\n\nWhere will you put your heart first? (You can change focus later.)",
            options: [
                { text: "Expansion: 'This town deserved more of us.'",   hint: "Focus: Expansion",  fn: function() { global.focus = "expansion";  tea_add_xp("expansion", 10);  tea_queue_event_by_key("tutorial"); } },
                { text: "Community: 'Everyone needs a second home.'",   hint: "Focus: Community",  fn: function() { global.focus = "community";  tea_add_xp("community", 10);  tea_queue_event_by_key("tutorial"); } },
                { text: "Innovation: 'Let's make it unlike anywhere.'", hint: "Focus: Innovation", fn: function() { global.focus = "innovation"; tea_add_xp("innovation", 10); tea_queue_event_by_key("tutorial"); } }
            ]
        },
        {
            key: "tutorial", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "Running the Shop",
            text: "Customers line up at the register. Click TAKE on their ticket (right side), then BREW to make it. You can also walk your character to the register or tea station and press E. Brewing is 50% faster while you stand at a station.\n\nHire Front of House staff to take orders and Baristas to brew them. Learn new recipes, buy a kitchen or an espresso machine, and grow your focus path.\n\nEvery night you pay rent and wages. Stay out of the red: three nights in a row below $0 and the bank takes the shop.\n\nSpace pauses. 1 / 2 / 3 change speed.",
            options: [ { text: "Flip the sign to OPEN", hint: "", fn: function() { } } ]
        },
        {
            key: "letter_register", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "A Note in the Drawer",
            text: "The cash drawer sticks again. When you yank it free, a folded receipt falls out. On the back, in your father's slanted handwriting:\n\n'Remember the names. Everything else is just tea.'",
            options: [ { text: "Keep it in your apron pocket.", hint: "+2 reputation", fn: function() { tea_add_rep(2); } } ]
        },
        {
            key: "letter_week", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "One Week",
            text: "Mrs. Albright from the hardware store lingers at the counter after paying. 'He talked about you constantly, you know. Said you'd figure it out faster than he did.' She pats your hand and goes.\n\nYou stand there a while before the next customer comes in.",
            options: [ { text: "Back to work.", hint: "+30 focus XP", fn: function() { if (global.focus != "") tea_add_xp(global.focus, 30); } } ]
        },
        {
            key: "letter_tin", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "For When It's Yours",
            text: "Behind the oolong in the back cabinet is a dented tin you've never seen. Taped to the lid: 'For when it's yours.' Inside is a roll of bills and a recipe card with half the ingredients smudged away.",
            options: [ { text: "Put the money back into the shop.", hint: "+$300, +40 Innovation XP", fn: function() { global.money += 300; tea_add_xp("innovation", 40); } } ]
        },
        {
            key: "content", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "Content",
            text: "After closing, you sit at the corner table where your father used to do the books. The chairs are up, the kettle is ticking as it cools, and the ledger finally balances with room to spare.\n\nPeople come here now. They know your name, and you know theirs. It isn't famous. It's enough. It's more than enough.\n\nYou think he'd be proud.",
            options: [
                { text: "Keep running the shop.", hint: "Continue playing", fn: function() { } },
                { text: "Hang up the apron.", hint: "Return to title", fn: function() { room_goto(Start); } }
            ]
        },
        {
            key: "gameover", story: true, path: "", weight: 0, cooldown: 0,
            cond: function() { return false; },
            title: "Closed",
            text: "The letter from the bank is polite and final. After three nights in the red, the loan is called in. You lock the door one last time and leave the key under the mat, the way he always did.",
            options: [ { text: "Start over.", hint: "", fn: function() { game_restart(); } } ]
        },

        // ================= KEY EVENTS =================
        {
            key: "storm", story: false, path: "", weight: 6, cooldown: 7,
            cond: function() { return global.day >= 4; },
            title: "Flash Flood Warning",
            text: "The radio crackles with a flash-flood warning. Rain is sheeting down Main Street and the creek behind the shop is rising fast. Across the road, the bakery is already stacking sandbags.",
            options: [
                { text: "Close early and sandbag the door.", hint: "-$200, close for the day", cost: 200,
                  fn: function() { global.money -= 200; global.force_close = true; tea_queue_message("Dry Floors", "The water creeps up to the step and stops. The shop is dry. You lose an afternoon of sales, but nothing else."); } },
                { text: "Stay open as a refuge.", hint: "Risky: could cost $700", fn: function() {
                    global.today.traffic_mult *= 0.4;
                    if (random(1) < 0.5) {
                        global.money -= 700; tea_add_rep(3);
                        tea_queue_message("Water Damage", "The creek comes over the bank just after two. You mop for hours and the floorboards by the door will need replacing.\n\nBut people saw your lights on all afternoon, and they remember that.\n\n-$700, +3 reputation");
                    } else {
                        tea_add_rep(5); tea_add_xp("community", 40);
                        tea_queue_message("A Beacon in the Storm", "The water never reaches you. Instead, half the street ends up drying off at your tables, trading stories over pots of tea.\n\n+5 reputation, +40 Community XP");
                    }
                } },
                { text: "Close up and hope for the best.", hint: "Free, but risky", fn: function() {
                    global.force_close = true;
                    if (random(1) < 0.6) { global.money -= 500; tea_queue_message("Soaked", "Nobody was there to stop the water. It ruins the bottom shelf of stock and warps the counter base.\n\n-$500"); }
                    else tea_queue_message("Lucky", "The storm passes the shop by. You got away with it this time.");
                } }
            ]
        },
        {
            key: "complaint", story: false, path: "", weight: 4, cooldown: 3,
            cond: function() { return global.today.angry >= 1; },
            title: "A Scathing Review",
            text: "Someone posts a one-star review: 'Waited forever, nobody even took my order. The old owner would be ashamed.' It's already getting shared around the town group.",
            options: [
                { text: "Send them a voucher for free drinks.", hint: "-$60, +3 reputation", cost: 60, fn: function() { global.money -= 60; tea_add_rep(3); tea_add_xp("community", 20); } },
                { text: "Reply publicly, apologize and explain.", hint: "+1 reputation", fn: function() { tea_add_rep(1); tea_add_xp("community", 10); } },
                { text: "Hire more help.", hint: "Opens Staff", fn: function() { global.modal = "staff"; } },
                { text: "Ignore it.", hint: "-4 reputation", fn: function() { tea_add_rep(-4); } }
            ]
        },
        {
            key: "inspection", story: false, path: "", weight: 5, cooldown: 6,
            cond: function() { return global.day >= 3; },
            title: "Health and Safety Inspection",
            text: "A county inspector with a clipboard steps through the door, unannounced. 'Routine visit. I'll need to see the kitchen and storage.'",
            options: [
                { text: "Let them in right away.", hint: "Roll the dice", fn: function() { tea_run_inspection(0); } },
                { text: "Stall for 20 minutes and deep-clean.", hint: "-$120, much better odds", cost: 120, fn: function() { global.money -= 120; tea_run_inspection(25); } },
                { text: "Ask them to come back another day.", hint: "-2 reputation", fn: function() { tea_add_rep(-2); } }
            ]
        },
        {
            key: "family", story: false, path: "", weight: 6, cooldown: 3,
            cond: function() { return global.day >= 2 && global.minute < 15 * 60; },
            title: "A Large Family Reservation",
            text: "The phone rings. A family in town for a reunion wants to bring a big group by this afternoon. Ten or so people, grandparents included, and they'd like the back tables kept for them.",
            options: [
                { text: "Welcome them!", hint: "$150 deposit, big group arrives", fn: function() {
                    global.money += 150;
                    var fam = choose("Okafor", "Delgado", "Nguyen", "Brennan", "Haddad", "Larsen");
                    tea_schedule_group(2, irandom_range(8, 12), "family", "The " + fam + " family", 0);
                    tea_add_xp("community", 30);
                } },
                { text: "Accept, but charge a private-booking fee.", hint: "+$400, -1 reputation", fn: function() {
                    global.money += 400; tea_add_rep(-1);
                    tea_schedule_group(2, irandom_range(8, 10), "family", "The reunion group", 0);
                    tea_add_xp("expansion", 30);
                } },
                { text: "Politely decline.", hint: "", fn: function() { } }
            ]
        },
        {
            key: "music", story: false, path: "", weight: 6, cooldown: 2,
            cond: function() { return global.day >= 2 && global.minute < 17 * 60; },
            title: "Live Music",
            text: "A folk duo with a fiddle case and a battered guitar asks if they can play in the corner tonight.",
            options: [
                { text: "Hire them for the evening.", hint: "-$150, big crowd + ambience", cost: 150, fn: function() {
                    global.money -= 150; global.today.music += 15; global.today.traffic_mult *= 1.4; tea_add_xp("community", 25);
                } },
                { text: "Let them play for tips.", hint: "Free, a little risky", fn: function() {
                    global.today.music += 8; global.today.traffic_mult *= 1.15; tea_add_xp("community", 10);
                    if (random(1) < 0.25) { tea_add_rep(-2); tea_queue_message("Enthusiastic", "They are... enthusiastic. Very loud. Two customers leave with their hands over their ears.\n\n-2 reputation"); }
                } },
                { text: "Not tonight.", hint: "", fn: function() { } }
            ]
        },

        // ================= EXPANSION =================
        {
            key: "supplier", story: false, path: "expansion", weight: 3, cooldown: 4,
            cond: function() { return global.day >= 2; },
            title: "A Bulk Supplier Calls",
            text: "A regional distributor offers you an exclusive bulk deal: pay up front and get 30% off ingredients for the next three days.",
            options: [
                { text: "Sign the deal.", hint: "-$300, cheap supplies, +60 Expansion XP", cost: 300, fn: function() { global.money -= 300; global.supply_deal_until = global.day + 2; tea_add_xp("expansion", 60); } },
                { text: "Haggle, then walk away.", hint: "+10 Expansion XP", fn: function() { tea_add_xp("expansion", 10); } }
            ]
        },
        {
            key: "storefront", story: false, path: "expansion", weight: 3, cooldown: 5,
            cond: function() { return global.day >= 3 && !global.upgrades.second_shop; },
            title: "An Empty Storefront",
            text: "You hear the old pharmacy in the next town over is up for lease. Big windows, good foot traffic. It's probably too soon. Probably.",
            options: [
                { text: "Drive over and scout it.", hint: "-$100, +50 Expansion XP", cost: 100, fn: function() { global.money -= 100; tea_add_xp("expansion", 50); } },
                { text: "Not yet.", hint: "", fn: function() { } }
            ]
        },
        {
            key: "poach", story: false, path: "expansion", weight: 2, cooldown: 5,
            cond: function() { return global.day >= 4; },
            title: "A Barista for Hire",
            text: "The coffee chain on the highway is cutting hours. One of their best baristas asks if you're hiring, and she'd take a lower wage to work somewhere local.",
            options: [
                { text: "Hire her on the spot.", hint: "Free Barista hire, +40 Expansion XP", fn: function() {
                    if (tea_staff_count("back") < global.staff_roles.back.cap) { array_push(global.staff, { name: "Lucia", role: "back", task: undefined, t: 0 }); tea_toast("Lucia joins as a Barista!", C_ACCENT); }
                    tea_add_xp("expansion", 40);
                } },
                { text: "Take her number for later.", hint: "+10 Expansion XP", fn: function() { tea_add_xp("expansion", 10); } }
            ]
        },

        // ================= COMMUNITY =================
        {
            key: "puppies", story: false, path: "community", weight: 3, cooldown: 5,
            cond: function() { return global.day >= 2; },
            title: "Puppies!",
            text: "A regular's dog just had a litter. She asks if she can hold a little adoption afternoon on your patio.",
            options: [
                { text: "Absolutely.", hint: "+3 reputation, more traffic, +50 Community XP", fn: function() { tea_add_rep(3); global.today.traffic_mult *= 1.3; tea_add_xp("community", 50); } },
                { text: "Kindly decline.", hint: "", fn: function() { } }
            ]
        },
        {
            key: "students", story: false, path: "community", weight: 3, cooldown: 4,
            cond: function() { return global.day >= 2; },
            title: "Finals Week",
            text: "A group of students from the community college ask if they can camp out and study. They'll buy drinks, but they'll also take up tables.",
            options: [
                { text: "Offer them a study-table discount.", hint: "-$40, +1 reputation, +40 Community XP", cost: 40, fn: function() { global.money -= 40; tea_add_rep(1); global.today.traffic_mult *= 1.15; tea_add_xp("community", 40); } },
                { text: "Welcome them, no discount.", hint: "+15 Community XP", fn: function() { tea_add_xp("community", 15); } }
            ]
        },
        {
            key: "fundraiser", story: false, path: "community", weight: 2, cooldown: 6,
            cond: function() { return global.day >= 5; },
            title: "The School Fundraiser",
            text: "The elementary school PTA asks if you'll donate a tea basket for their silent auction.",
            options: [
                { text: "Donate a generous basket.", hint: "-$80, +3 reputation, +40 Community XP", cost: 80, fn: function() { global.money -= 80; tea_add_rep(3); tea_add_xp("community", 40); } },
                { text: "Donate a gift card instead.", hint: "+1 reputation, +15 Community XP", fn: function() { tea_add_rep(1); tea_add_xp("community", 15); } }
            ]
        },

        // ================= INNOVATION =================
        {
            key: "butterfly", story: false, path: "innovation", weight: 3, cooldown: 4,
            cond: function() { return global.day >= 2; },
            title: "A Traveling Merchant",
            text: "A merchant with a van full of jars stops by. Among them: dried butterfly pea flowers that turn tea a vivid blue, and change to purple with a squeeze of lemon.",
            options: [
                { text: "Buy a sample crate.", hint: "-$200, +60 Innovation XP", cost: 200, fn: function() { global.money -= 200; tea_add_xp("innovation", 60); } },
                { text: "Just chat about where it comes from.", hint: "+15 Innovation XP", fn: function() { tea_add_xp("innovation", 15); } }
            ]
        },
        {
            key: "blogger", story: false, path: "innovation", weight: 3, cooldown: 4,
            cond: function() { return global.day >= 3; },
            title: "The Food Blogger's Dare",
            text: "A food blogger with a surprisingly big following dares you to invent a brand new drink, on the spot, on camera.",
            options: [
                { text: "Accept the challenge.", hint: "Risky", fn: function() {
                    if (random(1) < 0.6) { tea_add_rep(5); tea_add_xp("innovation", 50); tea_queue_message("It Works!", "Smoked pear, ginger and a whisper of cardamom. The blogger takes a second sip, which is apparently a big deal.\n\n+5 reputation, +50 Innovation XP"); }
                    else { tea_add_rep(-2); tea_add_xp("innovation", 30); tea_queue_message("It Does Not Work", "Pickled plum oolong. The face the blogger makes will be a meme by tonight. You learned something, at least.\n\n-2 reputation, +30 Innovation XP"); }
                } },
                { text: "Politely decline.", hint: "", fn: function() { } }
            ]
        },
        {
            key: "notebook", story: false, path: "innovation", weight: 3, cooldown: 999,
            cond: function() { return global.day >= 5; },
            title: "Dad's Notebook",
            text: "Clearing out the storeroom, you find a spiral notebook full of your father's experiments: ratios, steep times, scribbled-out failures, and one page just labeled 'THE ONE?'",
            options: [
                { text: "Study it late into the night.", hint: "+80 Innovation XP", fn: function() { tea_add_xp("innovation", 80); } },
                { text: "Not ready to read it yet.", hint: "", fn: function() { } }
            ]
        }
    ];
}