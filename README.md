# Imperial College Year 3 Microprocessor Lab: Heart Rate Monitor
---
## Charlotte Feazey-Noble & Shafiat Dewan 
---

Repository for Year 3 Physics Microprocessor lab. Contains multiple assembly files for a [PIC18F87K22 microprocessor](https://ww1.microchip.com/downloads/en/DeviceDoc/39960d.pdf) that use the [SEN0203 sensor](https://wiki.dfrobot.com/Heart_Rate_Sensor_SKU__SEN0203) to output heart rate of the user. 

Reads an analog signal output from the pulse sensor into pin RA0 and converts it to a digital signal. Reads a +5V external voltage reference on pin RA3. Uses the built-in TIMER0 interrupt set to operate at 62.5 kHz so there is an interrupt every second. Continuously compares the digital signal with a set threshold value, and counts the number of times that the signal goes above the threshold within the one second interrupt. After 15 seconds (15 interrupts) a value of heart rate is calculated and output to the LCD. This value is updated every subsequent second.