package state_pkg;
  typedef enum logic[2:0] {
  S_VIDLE,  
  S_VPULSE,
  S_VBP,
  S_VACTIVE,
  S_VFP
  } Vstate_t;

  typedef enum logic[2:0] {
    S_HIDLE,  
    S_HPULSE,
    S_HBP,
    S_HACTIVE,
    S_HFP
  } Hstate_t;

endpackage