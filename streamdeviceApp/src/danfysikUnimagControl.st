program danfysikUnimagControl

/*
 * EPICS State Notation Language program for Danfysik SYS8X00 UNIMAG interface
 * Handles automatic polarity switching and sequencing for Danfysik power supply
 * 
 * This program monitors the UNIMAG current setpoint and automatically:
 * 1. Determines required polarity based on sign of current
 * 2. Ramps to zero if polarity change is needed
 * 3. Powers off the supply
 * 4. Changes polarity
 * 5. Powers on and ramps to target current
 */

option +r;  /* Make reentrant */
option -c;  /* Don't wait for all channels to connect */

/* C declarations */
%% #include <math.h>
%% #include <string.h>
%% #include <epicsTime.h>

/* PV declarations - UNIMAG Interface */
double unimag_current_sp;
assign unimag_current_sp to "{DEVICE}:UNIMAG:CURRENT_SP";
monitor unimag_current_sp;

double unimag_current_rb;
assign unimag_current_rb to "{DEVICE}:UNIMAG:CURRENT_RB";
monitor unimag_current_rb;

/* PV declarations - Hardware Interface */
double i_sp;
assign i_sp to "{DEVICE}:I_SP";

double i_rb;
assign i_rb to "{DEVICE}:I_RB";
monitor i_rb;

int power_sp;
assign power_sp to "{DEVICE}:POWER_SP";

int power_on;
assign power_on to "{DEVICE}:MAIN_PWR_ON";
monitor power_on;

string pol_rb;
assign pol_rb to "{DEVICE}:POL_RB";
monitor pol_rb;

int pol_sp;
assign pol_sp to "{DEVICE}:POL_SP";

int reset_cmd;
assign reset_cmd to "{DEVICE}:RESET";

string status;
assign status to "{DEVICE}:STATUS";
monitor status;

string ctrl_mode;
assign ctrl_mode to "{DEVICE}:CTRL_MODE";
monitor ctrl_mode;

/* PV declarations - UNIMAG Status */
int pol_changing;
assign pol_changing to "{DEVICE}:UNIMAG:POL_CHANGING";

int ramping;
assign ramping to "{DEVICE}:UNIMAG:RAMPING";

int target_pol;
assign target_pol to "{DEVICE}:UNIMAG:TARGET_POL";

double target_abs_curr;
assign target_abs_curr to "{DEVICE}:UNIMAG:TARGET_ABS_CURR";

int seq_step;
assign seq_step to "{DEVICE}:UNIMAG:SEQ_STEP";

int auto_enable;
assign auto_enable to "{DEVICE}:UNIMAG:AUTO_ENABLE";
monitor auto_enable;

int manual_pol;
assign manual_pol to "{DEVICE}:UNIMAG:MANUAL_POL";
monitor manual_pol;

double timeout_val;
assign timeout_val to "{DEVICE}:UNIMAG:TIMEOUT";
monitor timeout_val;

int debug_level;
assign debug_level to "{DEVICE}:UNIMAG:DEBUG";
monitor debug_level;

int op_count;
assign op_count to "{DEVICE}:UNIMAG:OP_COUNT";

int error_count;
assign error_count to "{DEVICE}:UNIMAG:ERROR_COUNT";

string last_error;
assign last_error to "{DEVICE}:UNIMAG:LAST_ERROR";

/* Event flags */
evflag current_sp_ef;
sync unimag_current_sp current_sp_ef;

evflag status_change_ef;
sync status status_change_ef;
sync power_on status_change_ef;
sync pol_rb status_change_ef;

/* State variables */
int requested_polarity;     /* 1=positive, 0=negative */
double requested_current;
double abs_current;
int polarity_change_needed;
int timeout_counter;
double start_time;
int operation_active;
int current_step;

/* Constants */
#define CURRENT_THRESHOLD 1.0
#define TIMEOUT_TICKS 300     /* 150 seconds with 0.5s delay */
#define POL_POSITIVE 1
#define POL_NEGATIVE 0

/* Debug levels */
#define DEBUG_OFF   0
#define DEBUG_ERROR 1  
#define DEBUG_WARN  2
#define DEBUG_INFO  3
#define DEBUG_DEBUG 4

/* Sequence steps */
#define STEP_IDLE         0
#define STEP_CHECK_POL    1
#define STEP_RAMP_ZERO    2
#define STEP_POWER_OFF    3
#define STEP_CHG_POLARITY 4
#define STEP_POWER_ON     5
#define STEP_SET_CURRENT  6
#define STEP_COMPLETE     7
#define STEP_ERROR        8

ss unimag_control {
    state INIT {
        entry {
            /* Initialize variables */
            operation_active = 0;
            timeout_counter = 0;
            polarity_change_needed = 0;
            current_step = STEP_IDLE;
            
            /* Set initial status */
            seq_step = STEP_IDLE;
            pvPut(seq_step);
            pol_changing = 0;
            pvPut(pol_changing);
            ramping = 0;  
            pvPut(ramping);
            
            printf("danfysikUnimagControl: Initialized\n");
        }
        
        when (delay(1.0)) {
            /* Get initial PV values */
            pvGet(auto_enable);
            pvGet(manual_pol);
            pvGet(timeout_val);
            pvGet(debug_level);
        } state IDLE
    }
    
    state IDLE {
        entry {
            if (debug_level >= DEBUG_DEBUG) {
                printf("danfysikUnimagControl: Entering IDLE state\n");
            }
            operation_active = 0;
            current_step = STEP_IDLE;
            seq_step = STEP_IDLE;
            pvPut(seq_step);
            pol_changing = 0;
            pvPut(pol_changing);
            ramping = 0;
            pvPut(ramping);
        }
        
        when (efTestAndClear(current_sp_ef) && auto_enable && !manual_pol) {
            /* New current setpoint received and auto mode enabled */
            requested_current = unimag_current_sp;
            abs_current = fabs(requested_current);
            
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: New setpoint: %.3f A\n", requested_current);
            }
            
            /* Determine requested polarity */
            if (requested_current >= 0.0) {
                requested_polarity = POL_POSITIVE;
            } else {
                requested_polarity = POL_NEGATIVE;
            }
            
            /* Store target values */
            target_pol = requested_polarity;
            pvPut(target_pol);
            target_abs_curr = abs_current;
            pvPut(target_abs_curr);
            
            /* Increment operation counter */
            pvGet(op_count);
            op_count++;
            pvPut(op_count);
            
            operation_active = 1;
            timeout_counter = 0;
            
            /* Get current polarity */
            pvGet(pol_rb);
        } state CHECK_POLARITY
        
        when (efTestAndClear(status_change_ef)) {
            /* Status changed - check for faults */
            pvGet(status);
            if (strstr(status, "!") != NULL && debug_level >= DEBUG_WARN) {
                printf("danfysikUnimagControl: Status change detected: %s\n", status);
            }
        } state IDLE
    }
    
    state CHECK_POLARITY {
        entry {
            if (debug_level >= DEBUG_DEBUG) {
                printf("danfysikUnimagControl: Checking polarity\n");
            }
            current_step = STEP_CHECK_POL;
            seq_step = STEP_CHECK_POL;
            pvPut(seq_step);
            
            /* Get current status */
            pvGet(pol_rb);
            pvGet(power_on);
            pvGet(i_rb);
            pvGet(ctrl_mode);
        }
        
        when (strcmp(ctrl_mode, "REM") != 0) {
            /* Not in remote mode */
            strcpy(last_error, "Not in remote mode");
            pvPut(last_error);
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: ERROR - Not in remote mode\n");
            }
        } state ERROR
        
        when ((requested_polarity == POL_POSITIVE && strcmp(pol_rb, "+") == 0) ||
              (requested_polarity == POL_NEGATIVE && strcmp(pol_rb, "-") == 0)) {
            /* Polarity is correct, no change needed */
            polarity_change_needed = 0;
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Polarity correct, setting current directly\n");
            }
        } state SET_CURRENT_DIRECT
        
        when ((requested_polarity == POL_POSITIVE && strcmp(pol_rb, "+") != 0) ||
              (requested_polarity == POL_NEGATIVE && strcmp(pol_rb, "-") != 0)) {
            /* Polarity change needed */
            polarity_change_needed = 1;
            pol_changing = 1;
            pvPut(pol_changing);
            
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Polarity change needed: %s -> %s\n", 
                       pol_rb, (requested_polarity == POL_POSITIVE) ? "+" : "-");
            }
            
            if (power_on && fabs(i_rb) > CURRENT_THRESHOLD) {
                /* Need to ramp to zero first */
                if (debug_level >= DEBUG_INFO) {
                    printf("danfysikUnimagControl: Current too high (%.3f A), ramping to zero\n", i_rb);
                }
            } state RAMP_TO_ZERO
            else {
                /* Current is low enough, can proceed */
            } state POWER_OFF
        } state CHECK_POLARITY
    }
    
    state RAMP_TO_ZERO {
        entry {
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Ramping to zero\n");
            }
            current_step = STEP_RAMP_ZERO;
            seq_step = STEP_RAMP_ZERO;
            pvPut(seq_step);
            ramping = 1;
            pvPut(ramping);
            
            /* Set current to zero */
            i_sp = 0.0;
            pvPut(i_sp);
            timeout_counter = 0;
        }
        
        when (fabs(i_rb) < CURRENT_THRESHOLD) {
            /* Current reached zero */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Current reached zero (%.3f A)\n", i_rb);
            }
            ramping = 0;
            pvPut(ramping);
        } state POWER_OFF
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            strcpy(last_error, "Timeout waiting for zero current");
            pvPut(last_error);
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: ERROR - Timeout waiting for zero current\n");
            }
            ramping = 0;
            pvPut(ramping);
        } state ERROR
        
        when (!power_on) {
            /* Power turned off externally */
            if (debug_level >= DEBUG_WARN) {
                printf("danfysikUnimagControl: Power turned off externally\n");
            }
            ramping = 0;
            pvPut(ramping);
        } state POWER_OFF
        
        when (delay(0.5)) {
            /* Keep checking */
        } state RAMP_TO_ZERO
    }
    
    state POWER_OFF {
        entry {
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Powering off\n");
            }
            current_step = STEP_POWER_OFF;
            seq_step = STEP_POWER_OFF;
            pvPut(seq_step);
            
            power_sp = 0;
            pvPut(power_sp);
            timeout_counter = 0;
        }
        
        when (delay(1.0)) {
            /* Wait for power off to complete */
            pvGet(power_on);
        } state WAIT_POWER_OFF
    }
    
    state WAIT_POWER_OFF {
        when (!power_on) {
            /* Power off confirmed */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Power off confirmed\n");
            }
        } state CHANGE_POLARITY
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            strcpy(last_error, "Timeout waiting for power off");
            pvPut(last_error);
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: ERROR - Timeout waiting for power off\n");
            }
        } state ERROR
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(power_on);
        } state WAIT_POWER_OFF
    }
    
    state CHANGE_POLARITY {
        entry {
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Changing polarity to %s\n", 
                       (requested_polarity == POL_POSITIVE) ? "positive" : "negative");
            }
            current_step = STEP_CHG_POLARITY;
            seq_step = STEP_CHG_POLARITY;
            pvPut(seq_step);
            
            /* Change polarity */
            pol_sp = requested_polarity;
            pvPut(pol_sp);
            timeout_counter = 0;
        }
        
        when (delay(2.0)) {
            /* Wait for polarity change */
            pvGet(pol_rb);
        } state WAIT_POLARITY
    }
    
    state WAIT_POLARITY {
        when ((requested_polarity == POL_POSITIVE && strcmp(pol_rb, "+") == 0) ||
              (requested_polarity == POL_NEGATIVE && strcmp(pol_rb, "-") == 0)) {
            /* Polarity confirmed */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Polarity change confirmed: %s\n", pol_rb);
            }
        } state POWER_ON
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            strcpy(last_error, "Timeout waiting for polarity change");
            pvPut(last_error);
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: ERROR - Timeout waiting for polarity change\n");
            }
        } state ERROR
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(pol_rb);
        } state WAIT_POLARITY
    }
    
    state POWER_ON {
        entry {
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Powering on\n");
            }
            current_step = STEP_POWER_ON;
            seq_step = STEP_POWER_ON;
            pvPut(seq_step);
            
            power_sp = 1;
            pvPut(power_sp);
            timeout_counter = 0;
        }
        
        when (delay(1.0)) {
            /* Wait for power on */
            pvGet(power_on);
        } state WAIT_POWER_ON
    }
    
    state WAIT_POWER_ON {
        when (power_on) {
            /* Power on confirmed */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Power on confirmed\n");
            }
        } state SET_CURRENT
        
        when (timeout_counter++ >= TIMEOUT_TICKS) {
            /* Timeout - cancel operation */
            strcpy(last_error, "Timeout waiting for power on");
            pvPut(last_error);
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: ERROR - Timeout waiting for power on\n");
            }
        } state ERROR
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(power_on);
        } state WAIT_POWER_ON
    }
    
    state SET_CURRENT_DIRECT {
        entry {
            /* No polarity change needed, check if we need to power on */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Setting current directly to %.3f A\n", abs_current);
            }
            current_step = STEP_SET_CURRENT;
            seq_step = STEP_SET_CURRENT;
            pvPut(seq_step);
            
            pvGet(power_on);
        }
        
        when (!power_on) {
            /* Need to power on first */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Need to power on first\n");
            }
            power_sp = 1;
            pvPut(power_sp);
        } state WAIT_POWER_ON_DIRECT
        
        when (power_on) {
            /* Already powered on, set current */
            i_sp = abs_current;
            pvPut(i_sp);
        } state COMPLETE
    }
    
    state WAIT_POWER_ON_DIRECT {
        when (power_on) {
            i_sp = abs_current;
            pvPut(i_sp);
        } state COMPLETE
        
        when (delay(0.5)) {
            /* Keep checking */
            pvGet(power_on);
        } state WAIT_POWER_ON_DIRECT
    }
    
    state SET_CURRENT {
        entry {
            /* Set the absolute current value */
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Setting current to %.3f A\n", abs_current);
            }
            current_step = STEP_SET_CURRENT;
            seq_step = STEP_SET_CURRENT;
            pvPut(seq_step);
            
            i_sp = abs_current;
            pvPut(i_sp);
        }
        
        when (delay(0.5)) {
        } state COMPLETE
    }
    
    state COMPLETE {
        entry {
            if (debug_level >= DEBUG_INFO) {
                printf("danfysikUnimagControl: Operation complete\n");
            }
            current_step = STEP_COMPLETE;
            seq_step = STEP_COMPLETE;
            pvPut(seq_step);
            
            pol_changing = 0;
            pvPut(pol_changing);
            ramping = 0;
            pvPut(ramping);
            operation_active = 0;
        }
        
        when (delay(1.0)) {
        } state IDLE
    }
    
    state ERROR {
        entry {
            if (debug_level >= DEBUG_ERROR) {
                printf("danfysikUnimagControl: Entering ERROR state\n");
            }
            current_step = STEP_ERROR;
            seq_step = STEP_ERROR;
            pvPut(seq_step);
            
            pol_changing = 0;
            pvPut(pol_changing);
            ramping = 0;
            pvPut(ramping);
            operation_active = 0;
            
            /* Increment error counter */
            pvGet(error_count);
            error_count++;
            pvPut(error_count);
        }
        
        when (delay(5.0)) {
            /* Wait 5 seconds before returning to idle */
        } state IDLE
    }
}