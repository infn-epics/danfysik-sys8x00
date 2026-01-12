program danfysikUnimagControl

/*
 * EPICS State Notation Language program for UNIMAG interface
 * Handles automatic polarity switching and sequencing for Danfysik power supply
 */

option +r;  /* Make reentrant */

/* C declarations */
%% #include <math.h>

/* PV declarations */
double current_sp;
assign current_sp to "{device}:CURRENT_SP";
monitor current_sp;

double current_rb;
assign current_rb to "{device}:CURRENT_RB";
monitor current_rb;

double curr_set;
assign curr_set to "{device}:I_SP";

int stat_polarity_pos;
assign stat_polarity_pos to "{device}:POL_NORMAL";
monitor stat_polarity_pos;

int stat_polarity_neg;
assign stat_polarity_neg to "{device}:POL_REVERSED";
monitor stat_polarity_neg;

int stat_standby;
assign stat_standby to "{device}:MAIN_PWR_ON";
monitor stat_standby;

int stat_power_on;
assign stat_power_on to "{device}:POWER_SP";
monitor stat_power_on;

int cmd_standby;
assign cmd_standby to "{device}:POWER_SP";

int cmd_power_on;
assign cmd_power_on to "{device}:POWER_SP";

int cmd_start_ramp;
assign cmd_start_ramp to "{device}:RAMP_RATE_SP";

int cmd_contactors_open;
assign cmd_contactors_open to "{device}:POWER_SP";

int cmd_polarity_pos_exec;
assign cmd_polarity_pos_exec to "{device}:POL_SP";

int cmd_polarity_neg_exec;
assign cmd_polarity_neg_exec to "{device}:POL_SP";

int cmd_reset;
assign cmd_reset to "{device}:RESET";
monitor cmd_reset;

/* Event flags */
evflag current_sp_ef;
sync current_sp current_sp_ef;

evflag cmd_reset_ef;
sync cmd_reset cmd_reset_ef;

/* State variables */
int requested_polarity;  /* 1=positive, 2=negative */
double requested_current;
double abs_current;
int polarity_change_needed;
int timeout_counter;

/* Constants */
#define CURRENT_THRESHOLD 2.0
#define TIMEOUT_TICKS 60  /* 30 seconds with 0.5s delay */
#define POL_POSITIVE 1
#define POL_NEGATIVE 2

ss unimag_control {
    state IDLE {
        when (efTestAndClear(current_sp_ef)) {
            /* New current setpoint received */
            requested_current = current_sp;
            abs_current = fabs(requested_current);
            
            /* Determine requested polarity */
            if (requested_current >= 0) {
                requested_polarity = POL_POSITIVE;
            } else {
                requested_polarity = POL_NEGATIVE;
            }
            
            /* Check if polarity change is needed */
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
            
            if ((requested_polarity == POL_POSITIVE && !stat_polarity_pos) ||
                (requested_polarity == POL_NEGATIVE && !stat_polarity_neg)) {
                polarity_change_needed = 1;
                timeout_counter = 0;
            } else {
                polarity_change_needed = 0;
            }
        } state CHECK_STATE
        
        when (efTestAndClear(cmd_reset_ef)) {
            /* Reset command cancels all operations */
            polarity_change_needed = 0;
            timeout_counter = 0;
        } state IDLE
    }
    
    state CHECK_STATE {
        entry {
            /* Get current status */
            pvGet(stat_power_on);
            pvGet(current_rb);
        }
        
        when (!polarity_change_needed) {
            /* No polarity change needed, just set current directly */
        } state SET_CURRENT_DIRECT
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) > CURRENT_THRESHOLD) {
            /* Need to ramp to zero first */
        } state RAMP_TO_ZERO
        
        when (polarity_change_needed && stat_power_on && fabs(current_rb) <= CURRENT_THRESHOLD) {
            /* Can go directly to standby */
        } state GO_STANDBY
        
        when (polarity_change_needed && !stat_power_on) {
            /* Already in standby or off, can change polarity */
        } state CHANGE_POLARITY
    }
    
    state RAMP_TO_ZERO {
        entry {
            /* Set current to zero and start ramp */
            curr_set = 0.0;
            pvPut(curr_set);
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
            timeout_counter = 0;
        }
        
        when (fabs(current_rb) < CURRENT_THRESHOLD) {
            /* Current reached zero */
        } state GO_STANDBY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for zero current\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state RAMP_TO_ZERO
    }
    
    state GO_STANDBY {
        entry {
            cmd_standby = 1;
            pvPut(cmd_standby);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_STANDBY
    }
    
    state WAIT_STANDBY {
        when (stat_standby) {
            /* Standby confirmed */
        } state CHANGE_POLARITY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for standby\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_STANDBY
    }
    
    state CHANGE_POLARITY {
        entry {
            /* Open contactors first */
            cmd_contactors_open = 1;
            pvPut(cmd_contactors_open);
            timeout_counter = 0;
        }
        
        when (delay(1.0)) {
            /* Change polarity after delay */
            if (requested_polarity == POL_POSITIVE) {
                cmd_polarity_pos_exec = 1;
                pvPut(cmd_polarity_pos_exec);
            } else {
                cmd_polarity_neg_exec = 2;
                pvPut(cmd_polarity_neg_exec);
            }
        } state WAIT_POLARITY_DELAY
    }
    
    state WAIT_POLARITY_DELAY {
        when (delay(2.0)) {
        } state WAIT_POLARITY
    }
    
    state WAIT_POLARITY {
        entry {
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
        }
        
        when ((requested_polarity == POL_POSITIVE && stat_polarity_pos) ||
              (requested_polarity == POL_NEGATIVE && stat_polarity_neg)) {
            /* Polarity confirmed */
            polarity_change_needed = 0;
        } state GO_POWERON
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            polarity_change_needed = 0;
            printf("unimagControl: Timeout waiting for polarity change\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
            polarity_change_needed = 0;
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(stat_polarity_pos);
            pvGet(stat_polarity_neg);
        } state WAIT_POLARITY
    }
    
    state GO_POWERON {
        entry {
            cmd_power_on = 1;
            pvPut(cmd_power_on);
            timeout_counter = 0;
        }
        
        when (delay(0.5)) {
        } state WAIT_POWERON
    }
    
    state WAIT_POWERON {
        when (stat_power_on) {
            /* Power on confirmed */
        } state SET_CURRENT
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            printf("unimagControl: Timeout waiting for power on\n");
        } state IDLE
        
        when (efTestAndClear(cmd_reset_ef)) {
        } state IDLE
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON
    }
    
    state SET_CURRENT {
        entry {
            /* Set the absolute current value */
            curr_set = abs_current;
            pvPut(curr_set);
        }
        
        when (delay(0.5)) {
        } state START_RAMP
    }
    
    state START_RAMP {
        entry {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        }
        
        when (delay(0.2)) {
        } state IDLE
    }
    
    state SET_CURRENT_DIRECT {
        entry {
            /* No polarity change needed, check if we need to power on */
            pvGet(stat_power_on);
        }
        
        when (!stat_power_on) {
            /* Need to power on first */
            cmd_power_on = 1;
            pvPut(cmd_power_on);
        } state WAIT_POWERON_DIRECT
        
        when (stat_power_on) {
            /* Already powered on */
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT
    }
    
    state WAIT_POWERON_DIRECT {
        when (stat_power_on) {
            curr_set = abs_current;
            pvPut(curr_set);
        } state RAMP_DIRECT
        
        when (delay(0.5)) {
            /* Keep checking */
        } state WAIT_POWERON_DIRECT
    }
    
    state RAMP_DIRECT {
        when (delay(0.5)) {
            cmd_start_ramp = 1;
            pvPut(cmd_start_ramp);
        } state IDLE_DIRECT
    }
    
    state IDLE_DIRECT {
        when (delay(0.2)) {
        } state IDLE
    }
}
