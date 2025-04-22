module aexis::time{
  
    use std::debug::print;
    use std::string;
    use supra_framework::timestamp; 

    struct ALL has key {microseconds: u64, miliseconds: u64, seconds: u64, minutes: u64, hours: u64, days: u64, weeks: u64, months: u64, years: u64}

    struct CONVERT_RATIOS has key,copy, drop {microseconds: u64, miliseconds: u64, seconds: u64, minutes: u64, hours: u64, days: u64, weeks: u64, months: u64, years: u64}

    const MILISECOND: u64 = 1_000;
    const SECOND: u64 = 1_000_000;
    const MINUTE: u64 = 60_000_000;
    const HOUR: u64 = 3_600_000_000;
    const DAY: u64 = 86_400_000_000;
    const WEEK: u64 = 604_800_000_000;
    const MONTH: u64 = 2_629_743_000_000;
    const YEAR: u64 = 31_556_926_000_000;

    #[view]
    public fun now_microseconds(): u64
    {
        let microseconds = timestamp::now_microseconds();
        move microseconds
    }

    #[view]
    public fun now_miliseconds(): u64
    {
        let miliseconds = now_microseconds() / MILISECOND;
        move miliseconds
    }

    #[view]
    public fun now_seconds(): u64
    {
        let seconds = now_microseconds() / SECOND;
        move seconds
    }

    #[view]
    public fun now_minutes(): u64
    {
        let minutes = now_microseconds() / MINUTE;
        move minutes
    }

    #[view]
    public fun now_hours(): u64
    {
        let hours = now_microseconds() / HOUR;
        move hours
    }

    #[view]
    public fun now_days(): u64
    {
        let days = now_microseconds() / DAY;
        move days
    }

    #[view]
    public fun now_weeks(): u64
    {
        let weeks = now_microseconds() / WEEK;
        move weeks
    }

    #[view]
    public fun now_months(): u64
    {
        let months = now_microseconds() / MONTH;
        move months
    }

    #[view]
    public fun now_years(): u64
    {
        let years = now_microseconds() / YEAR;
        move years
    }
 
    #[view]
    public fun all(): ALL {

        let new_struct = ALL {
            microseconds: now_microseconds(),
            miliseconds: now_miliseconds(),
            seconds: now_seconds(),
            minutes: now_minutes(),
            hours: now_hours(),
            days: now_days(),
            weeks: now_weeks(),
            months: now_months(),
            years: now_years(),
        };

        move new_struct
    }

    #[view]
    public fun convert_ratios(): CONVERT_RATIOS {

        let _ratios = CONVERT_RATIOS {
            microseconds:  0,
            miliseconds: MILISECOND,
            seconds: SECOND,
            minutes: MINUTE,
            hours: HOUR,
            days: DAY,
            weeks: WEEK,
            months: MONTH,
            years: YEAR,
        };

        move _ratios
    }
 
    #[test(framework = @0x1)]
    fun testing(framework: signer)
    {

        timestamp::set_time_has_started_for_testing(&framework);  
        timestamp::update_global_time_for_test(1742743442014014);

        print(&now_microseconds());
        print(&now_miliseconds());
        print(&now_seconds());
        print(&now_minutes());
        print(&now_hours());
        print(&now_days());
        print(&now_weeks());
        print(&now_months());
        print(&now_years());
        print(&convert_ratios());

    }   
}
