Config = {}
Config.MoneyWash = {
    Enabled = true,
    WashRate = 0.7,
    WashAmount = 1000,
    ProcessTime = 6000,
    NPC = {
        coords = vector3(62.19, -88.09, 58.20),
        heading = 160.0,
        model = "a_m_m_business_01"
    },
    InteractionDistance = 2.0
}

Config.Routes = {
    ['weed'] = {
        Enabled = true,
        Label = "Drogen Route",
        Collector = {
            Label = "Weed Sammer",
            Blip = {
                Enabled = false,
                Sprite = 496,
                Color = 2,
                Scale = 0.8
            },
            Location = {
                coords = vector3(2224.18, 5577.34, 53.85),
                radius = 10.0 
            },
            RequiredItem = nil,
            Items = {
                {
                    name = "weed",
                    label = "Weed",
                    amountMin = 1,
                    amountMax = 1,
                    chance = 100 
                }
            },
            ProcessTime = 8000,
            Animation = {
                type = "animation",
                dict = "amb@world_human_gardener_plant@female@base",
                anim = "base_female",
                flag = 1
            },
            InteractionDistance = 3.0
        },

        Processor = {
            Label = "Weed Labor",
            Blip = {
                Enabled = false,
                Sprite = 499,
                Color = 1,
                Scale = 0.8
            },
            Location = {
                coords = vector3(1337.13, 4391.82, 44.34),
                radius = 2.4
            },
            RequiredItem = {
                name = "weed",
                label = "Weed",
                amount = 2
            },
            OutputItem = {
                name = "joint",
                label = "Joint",
                amount = 1
            },
            ProcessTime = 12000,
            Animation = {
                type = "animation",
                dict = "missheistdockssetup1clipboard@idle_a",
                anim = "idle_a",
                flag = 1
            },
            InteractionDistance = 3.0
        },

        Seller = {
            Label = "Weed Dealer",
            Blip = {
                Enabled = false,
                Sprite = 126,
                Color = 3,
                Scale = 0.8
            },
            NPC = {
                coords = vector3(192.01, -2226.65, 6.98),
                heading = 88.72,
                model = "s_m_y_dealer_01"
            },
            Items = {
                {
                    name = "joint",
                    label = "Joint",
                    amount = 1,
                    payment = {
                        type = "black_money",
                        amount = 75,
                        amountMin = 75,
                        amountMax = 115
                    }
                }
            },
            ProcessTime = 5000,
            Animation = {
                type = "animation",
                dict = "mp_common",
                anim = "givetake1_a",
                flag = 16
            },
            InteractionDistance = 3.0
        }
    },
    ['fishing'] = {
        Enabled = true,
        Label = "Angelspot",
        
        Collector = {
            Label = "Angelspot",
            Blip = {
                Enabled = true,
                Sprite = 269,
                Color = 0,
                Scale = 0.8
            },
            Location = {
                coords = vector3(181.0998, -964.1566, 29.5503),
                radius = 5.0
            },
            RequiredItem = {
                name = "fishingrod",
                label = "Fishing Rod"
            },
            Items = {
                {
                    name = "trout",
                    label = "Trout",
                    amountMin = 1,
                    amountMax = 1,
                    chance = 25
                },
                {
                    name = "salmon",
                    label = "Salmon",
                    amountMin = 1,
                    amountMax = 1,
                    chance = 25
                },
                {
                    name = "tuna",
                    label = "Tuna",
                    amountMin = 1,
                    amountMax = 1,
                    chance = 25
                },
                {
                    name = "anchovy",
                    label = "Anchovy",
                    amountMin = 1,
                    amountMax = 1,
                    chance = 25
                }
            },
            ProcessTime = 10000,
            Animation = {
                type = "scenario",
                name = "world_human_stand_fishing"
            },
            InteractionDistance = 3.0
        },
        
        Seller = {
            Label = "Fisch Verkäufer",
            Blip = {
                Enabled = true,
                Sprite = 266,
                Color = 4,
                Scale = 0.8
            },
            NPC = {
                coords = vector3(234.49, -933.61, 31.51),
                heading = 70.70,
                model = "s_m_m_dockwork_01"
            },
            Items = {
                {
                    name = "trout",
                    label = "Trout",
                    amount = 1,
                    payment = {
                        type = "money",
                        amount = 25,
                        amountMin = 21,
                        amountMax = 48
                    }
                },
                {
                    name = "salmon",
                    label = "Salmon",
                    amount = 1,
                    payment = {
                        type = "money",
                        amount = 35,
                        amountMin = 28,
                        amountMax = 42
                    }
                },
                {
                    name = "tuna",
                    label = "Tuna",
                    amount = 1,
                    payment = {
                        type = "money",
                        amount = 49,
                        amountMin = 42,
                        amountMax = 56
                    }
                },
                {
                    name = "anchovy",
                    label = "Anchovy",
                    amount = 1,
                    payment = {
                        type = "money",
                        amount = 11,
                        amountMin = 7,
                        amountMax = 14
                    }
                }
            },
            ProcessTime = 2500,
            Animation = {
                type = "animation",
                dict = "mp_common",
                anim = "givetake1_a",
                flag = 16
            },
            InteractionDistance = 1.7
        }
    },
}

Config.MaxDistance = 10.0
Config.Debug = false