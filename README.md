<img width="1451" height="1284" alt="image" src="https://github.com/user-attachments/assets/6d59b5fb-3dd3-48f7-b784-99eb71886043" />
<img width="1662" height="1233" alt="image" src="https://github.com/user-attachments/assets/49b9ff86-f12a-4a54-9bdd-4126a56d9882" />
These can all be solved (with the exception of position) with a Mahony attitude filter:
reduce kp when |a| different enough from g

```
// Helper conventions:
// mul32(a,b,Qout)   -> multiply a and b, return in Qout
// inv_sqrt_fixed(x) -> 1/sqrt(x), returns Q1.31
// clamp64(x,limit)  -> saturate to ±limit
// All q[i] stored in Q1.31
// Gyros in Q6.26, accel/mag normalized to Q1.31

// State variables
q[4]          // quaternion [q0,q1,q2,q3], Q1.31
integral[3]   // integral error accumulator, wide 64-bit
Kp, Ki        // proportional and integral gains in Q1.31
dt            // timestep in Q16.16 (or Q1.31 scaled)

// MAIN LOOP, every dt:
loop {

  //--------------------------------------------------
  // (1) Read & scale sensors
  ax,ay,az  // accel raw, scaled to Q1.31
  gx,gy,gz  // gyro in Q6.26 (rad/s)
  mx,my,mz  // magnetometer (optional), Q1.31

  //--------------------------------------------------
  // (2) Normalize accelerometer
  asq  = ax*ax + ay*ay + az*az         // wide, up to 64b
  inv  = inv_sqrt_fixed(asq)           // Q1.31
  axn  = mul32(ax, inv, Q1.31)
  ayn  = mul32(ay, inv, Q1.31)
  azn  = mul32(az, inv, Q1.31)

  //--------------------------------------------------
  // (3) Estimate gravity vector v from quaternion
  v_x = 2 * ( mul32(q1,q3,Q1.31) - mul32(q0,q2,Q1.31) )
  v_y = 2 * ( mul32(q0,q1,Q1.31) + mul32(q2,q3,Q1.31) )
  v_z = (mul32(q0,q0,Q1.31) - mul32(q1,q1,Q1.31)
        -mul32(q2,q2,Q1.31) + mul32(q3,q3,Q1.31))

  //--------------------------------------------------
  // (4) Error term: cross product of accel vs est gravity
  e_x = mul32(ayn,v_z,Q1.31) - mul32(azn,v_y,Q1.31)
  e_y = mul32(azn,v_x,Q1.31) - mul32(axn,v_z,Q1.31)
  e_z = mul32(axn,v_y,Q1.31) - mul32(ayn,v_x,Q1.31)

  //--------------------------------------------------
  // (5) Integral feedback (accumulate)
  integral_x = clamp64(integral_x + mul32(Ki*dt, e_x, Q1.31), LIMIT)
  integral_y = clamp64(integral_y + mul32(Ki*dt, e_y, Q1.31), LIMIT)
  integral_z = clamp64(integral_z + mul32(Ki*dt, e_z, Q1.31), LIMIT)

  //--------------------------------------------------
  // (6) Corrected gyro values
  corr_x = gx + mul32(Kp, e_x, Q6.26) + (integral_x >> SCALE)
  corr_y = gy + mul32(Kp, e_y, Q6.26) + (integral_y >> SCALE)
  corr_z = gz + mul32(Kp, e_z, Q6.26) + (integral_z >> SCALE)

  //--------------------------------------------------
  // (7) Quaternion derivative qdot
  // Note: cast corr_x/y/z from Q6.26 into Q1.31 intermediate
  qdot0 = -0.5 * ( mul32(q1,corr_x,Q1.31) + mul32(q2,corr_y,Q1.31) + mul32(q3,corr_z,Q1.31) )
  qdot1 =  0.5 * ( mul32(q0,corr_x,Q1.31) + mul32(q2,corr_z,Q1.31) - mul32(q3,corr_y,Q1.31) )
  qdot2 =  0.5 * ( mul32(q0,corr_y,Q1.31) - mul32(q1,corr_z,Q1.31) + mul32(q3,corr_x,Q1.31) )
  qdot3 =  0.5 * ( mul32(q0,corr_z,Q1.31) + mul32(q1,corr_y,Q1.31) - mul32(q2,corr_x,Q1.31) )

  //--------------------------------------------------
  // (8) Integrate quaternion
  q0 = q0 + mul32(qdot0, dt, Q1.31)
  q1 = q1 + mul32(qdot1, dt, Q1.31)
  q2 = q2 + mul32(qdot2, dt, Q1.31)
  q3 = q3 + mul32(qdot3, dt, Q1.31)

  //--------------------------------------------------
  // (9) Normalize quaternion
  qnormsq = q0*q0 + q1*q1 + q2*q2 + q3*q3
  invq    = inv_sqrt_fixed(qnormsq)
  q0 = mul32(q0, invq, Q1.31)
  q1 = mul32(q1, invq, Q1.31)
  q2 = mul32(q2, invq, Q1.31)
  q3 = mul32(q3, invq, Q1.31)
}
```

<img width="1307" height="1126" alt="image" src="https://github.com/user-attachments/assets/ef1066f4-e888-4564-aae4-4f0c4251c45b" />
<img width="943" height="1079" alt="image" src="https://github.com/user-attachments/assets/2f55b0e0-0064-4f68-9b2d-e6a45e01bbc5" />
<img width="994" height="1107" alt="image" src="https://github.com/user-attachments/assets/ca0a60c6-fd6d-4a4c-9b3c-004c9e2bac97" />
