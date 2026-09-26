#import "@preview/acrostiche:0.7.0": acr

= Introduction

#acr("SSTV") is an analog method of communication designed for image transfer via radio signals on a narrow band. Early concepts of image transfer via radio waves have existed since the late 1950s with a formal authorization by the Federal Communications Commission in 1968 @sstv-handbook[p.~9-10]. Despite its age, SSTV remains in active use within the amateur radio community. The International Space Station, for example, regularly transmits SSTV images through the #acr("ARISS") program @ariss-sstv which are received by thousands of operators @ariss-25years.

In alignment with the aforementioned amateur radio community, it was decided to include an #acr("SSTV") transmitter on the MOVE-IIIa satellite. MOVE-IIIa is the first mission of the third iteration of satellites designed and built by the #acr("MOVE") project, a student-led group focusing on space hardware based in Munich. MOVE-IIIa serves three distince purposes. The project will detect and quantify micro-debris in orbit, downlink captured images via #acr("SSTV") and educate students on how to design, build and operate an actual satellite @move-iiia.

This thesis concerns the architecture and implementation of software for an #acr("SSTV") system for the use on a satellite such as MOVE-IIIa. It first discusses the theoretcial concepts related to #acr("SSTV"), outlines the constraints for the use on a satellite mission and elaborates on the architectural and implementation choices. Finally, the system is verified against the constraints and a verdict about the success of the firmware is reached. A special emphasis is placed on the modularity of the software, which should be deployable on all systems that match the constraints, rather than only MOVE-IIIa.

The hardware design of the system as well as the other satellite and ground station components involved in an #acr("SSTV") transmission are out of scope for this thesis.

