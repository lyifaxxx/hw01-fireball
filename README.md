# [Project 1: Noise-Based Fireball](https://github.com/CIS-566-Fall-2022/hw01-fireball-base)
#### Yifan Lu        
#### University of Pennsylvania

#### [Project Link (click me!)](https://lyifaxxx.github.io/hw01-fireball/)

![](img/all.gif)

## Introduction
This project is a procedural-generated fireball. Users can toogle several parameters including color, speed, brightness to create a custom fireball.



## Project Feature

### Adjustable Noise-based Shape
The overall shape of the fireball is determined by several types and layers of noise functions which make the shape look dynamic and organic.



### Color the Fireball
Here is a picture to the Real Sun in our Solar system.

![image](https://github.com/user-attachments/assets/a609ef76-9a88-40a9-b07a-f792a8482ed4)


The color gradient of the sun from higher temperature to lower looks like this:

```
black - white - yellow - red - black
```

In order to blend/interpolate them in a (scientifically) correct way, I introduced the "fire intensity" mask. It is determined by the followings:

- view direction
- tex coord on sphere surface
- noises (mainly fbm noise)

![](img/fireIntensity.gif)


Because the edge of our fireball should be less intense, it is necessary to consider the view direction.

Many wizards and witchs and magicians perform different types of fire magic. They threatened me to add more colors otherwise they will fireball me. So I use a hue mapping towards the original color which allows them to define a base color from the UI.

![](img/colorChanging.gif)

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
This project provides four artist-friendly presets that can be shown with a single click:
- Authentic Fireball

![](img/preset1.gif)

- Warm Orange

![](img/preset2.gif)

- Ice Wizard

![](img/preset3.gif)

- Wild Fire

![](img/preset4.gif)


## User Control
![image](https://github.com/user-attachments/assets/40c43117-cf8d-4761-98db-4f89fb5a9b5b)

The parameters for fireball shader will only be shown if the shader is selected to "fireball". They are under the folder "fireball parameters".

## References

1. Reference Pictures:

![](img/reference.png)

3. [shadertoy link](https://www.shadertoy.com/view/4dXGR4)
