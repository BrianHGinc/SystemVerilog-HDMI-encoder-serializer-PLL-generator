set_time_format -unit ns -decimal_places 3
create_clock -period 20 clk

derive_pll_clocks
derive_clock_uncertainty
