
  // function get_solution(dt, N, R0, D_incbation, D_infectious, DF, CFR) {
  //   var steps = 220
  //   var sample_step = 2

  //   var method = Integrators["RK4"]
  //   function f(t, x){

  //     // SEIR ODE
  //     if (t > InterventionTime){
  //       var beta = (InterventionAmt)*R0/(D_infectious)
  //     } else {
  //       var beta = R0/(D_infectious)
  //     }
  //     var a    = 1/D_incbation
  //     var gamma = 1/D_infectious
      
  //     var S = x[0] // Susectable
  //     var E = x[1] // Exposed
  //     var I = x[2] // Infectious
  //     var R = x[3] // Recovered
  //     var F = x[4] // Fully Recovered
  //     var D = x[5] // Dead

  //     var dS = -beta*I*S
  //     var dE = beta*I*S - a*E
  //     var dI = a*E - gamma*I
  //     var dR = gamma*I - (1/DF)*R
  //     var dF = (1-CFR)*(1/DF)*R
  //     var dD = CFR*(1/DF)*R

  //     //      0   1   2   3   4   5
  //     return [dS, dE, dI, dR, dF, dD]
  //   }

  //   var v = [1, 0, 1/N, 0, 0, 0]
  //   var t = 0

  //   var P = [];
  //   while (steps--) { 
  //     v =integrate(method,f,v,t,dt); 
  //     t+=dt
  //     if (steps % (sample_step) == 0) {
  //           //  Dead    Hospital  0    Exposed
  //       P.push([N*v[5], 0,        0,   N*(v[2]),N*v[1]])
  //     }
  //   }
  //   return {"P": P, 
  //           "tmax": t, 
  //           "deaths": N*v[5], 
  //           "total": v[4] }
  // }

  // function get_solution(dt, N, R0, D_incbation, D_infectious, D_to_hospital, D_recovery, P_SEVERE, CFR, InterventionTime, InterventionAmt) {

  //   var interpolation_steps = 10
  //   var steps = 420*interpolation_steps
  //   var dt = dt/interpolation_steps
  //   var sample_step = interpolation_steps

  //   var method = Integrators["RK4"]
  //   function f(t, x){

  //     // SEIR ODE
  //     if (t > InterventionTime){
  //       var beta = (InterventionAmt)*R0/(D_infectious)
  //     } else {
  //       var beta = R0/(D_infectious)
  //     }
  //     var a     = 1/D_incbation
  //     var gamma = 1/D_infectious
      
  //     var S  = x[0]    // Susectable
  //     var E  = x[1]    // Exposed
  //     var I  = x[2]    // Infectious 
  //     var RM = x[3]    // Recovering (Mezzanine)     | 
  //     var RH = x[4]    // Recovering (Severe Casees) | Removed
  //     var R  = x[5]    // Recovered  (Full)          | from population
  //     var D  = x[6]    // Dead                       |

  //     var dS  = -beta*I*S
  //     var dE  = beta*I*S - a*E
  //     var dI  = a*E - gamma*I
  //     var dRM = gamma*I - (1/D_to_hospital)*RM
  //     var dRH = P_SEVERE*(1/D_to_hospital)*RM - (1/D_recovery)*RH
  //     var dR  = 0.8*(1/D_to_hospital)*RM + (1-CFR/P_SEVERE)*(1/D_recovery)*RH
  //     var dD  = (CFR/P_SEVERE)*(1/D_recovery)*RH

  //     //      0   1   2   3    4    5   6
  //     return [dS, dE, dI, dRM, dRH, dR, dD]
  //   }

  //   var v = [1, 0, 1/N, 0, 0, 0, 0]
  //   var t = 0

  //   var P  = []
  //   var TI = []
  //   while (steps--) { 
  //     if ((steps+1) % (sample_step) == 0) {
  //           //  Dead    Hospital  0    Exposed
  //       P.push([N*v[6], N*(v[4]), N*(v[2]),N*v[1] ])
  //       TI.push(N*(1-v[0]))
  //     }
  //     v =integrate(method,f,v,t,dt); 
  //     t+=dt
  //   }
  //   return {"P": P, 
  //           "deaths": N*v[6], 
  //           "total": 1-v[0],
  //           "total_infected": TI}
  // }

  // $: D_recovery_mild   = 14  
  // $: D_recovery_severe = 14
  // $: D_death = Time_to_death - Time_to_hospital - D_incbation 
