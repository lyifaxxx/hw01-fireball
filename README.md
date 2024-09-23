# [Project 1: Noise-Based Fireball](https://github.com/CIS-566-Fall-2022/hw01-fireball-base)
#### Yifan Lu        
#### University of Pennsylvania


## Introduction
This project 

## User Control

## Project Feature

### Adjustable Noise-based Shape
The overall shape of the fireball is determined by several types and layers of noise functions which make the shape look dynamic and organic.

### Color the Fireball
Here is a picture to the Real Sun in our Solar system.

The color gradient of the sun from higher temperature to lower looks like this:
```
color gradient of the sun from higher temperature to lower:
black - purple - blue - white - yellow - red - black
```

### Alpha Control
Fire in the nature will fade into air. The best way I have to achieve this effect is to tweak alpha value accordingly. 

The alpha value is determined by 3 terms:
- The radius of the surface vertex point
- Fire intensity. Higher fire intensity yields smaller alpha value.
- View direction. Smaller viewing direction are more solid looking.

This is what alpha mask looks like:

![](img/alpha.gif)

### Fake Post-Process
After the overall color for the fireball is computed by color gradient and fire intensity, I applied a noise to it to achieve a filem-grid effect. The process is done in the same fragment shader where the color are computed, so it supposed to be a "fake" post process.

![](img/noiseCom.png)

The comparison of noise on/off under the "Wild Fire" preset above shows that the "fake" post process film-grid adds a more realistic touch to the fireball.

### Presets



## References
1. Reference Pictures:
![](img/reference.png)
3. shadertoy link
