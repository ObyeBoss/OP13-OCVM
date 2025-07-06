![ocvm](https://imgur.com/VoojOSI "op13 ocvm")](https://github.com/ObyeBoss/OP13-OCVM)
# OCVM OnePlus13 OOS15 camera mod

**OCVM** is a comprehensive camera mod that aims at optimizing and boosting all aspects of *OnePlus 13* imaging process. Given that Oppo camera stack provides an immense level of flexibility via whopping amount of comprehensive config interfaces to control many parts of imaging system directly. And with most important parts of the stack - HAL and its subcomponents being almost identical to those of *Oppo find x8 ultra* (*fx8u*). This opens a plethora of possibilities to experiment with and provide an all-rounder full-fledged package.
Mod comes in two packages: 
- A `main module` that is designed to optimize both the stock camera application boosting its quality, as well as third-party cameras (like *gcam*) but with less impact as that would require more low-level patches, that may (or may not) be added in the future. 
- An `addon module` with processing ported from *Oppo find x8 ultra* that affects stock app only.
---


> ## :one: Main module
> Aims at general optimization with image quality being major priority. Fights atrocious levels of sharpening & denoise, corrects various oplus mistakes/overlooks, disables what shouldn't be, enables what should, adds & reworks what can be reused from *fx8u*.
>
>> - ### **Features:**
>> - #### **Blobs**
>>   + disabled jpeg compression
>>   + HAL noise reduction api2 key skip
>>   + boosted thdr deconvolution
>> + #### **Sensor**
>>   + custom noise models for main & front lenses
>>   + disabled anr/ipe/demosaic denoise for main & tele lenses (**by savitar**)
>> + #### **Vendor interfaces**
>>   + upstreamed, corrected & reworked HAL config
>>   + upstreamed & reworked mode config
>>   + upstreamed & reworked aux switch config
>>   + upstreamed & reworked hr config
>>   + upstreamed & reworked ois/eis configs
>>   + edited per-sensor configs
>>     + upstreamed keys/values from *fx8u*
>>     + corrected lux parameters
>>     + disabled denoising/sharpening
>>   + edited various sw<->hw configs
>>     + added various internal keys
>>     + optimized various keys values
>>     + enabled various hidden cam app features
>
>> - ### **Known bugs:**
>>   - #### uwide to main camera switching in photo modes hangs camera
>>   - #### laggy portrait mode preview
>
>
> :exclamation: **Module clears stock camera app data** :exclamation:
>
> **you will need to set camera app again after module installation**
>

> ## :two: Addon module
> Ported *fx8u* imaging blobs. Corrects their work (to possible extend) on *op13*, restores microdetails & textures rendition in hdr mode.
>
>> - ### **Features:**
>> - #### **Blobs**
>>   + upstreamed & corrected various blobs from *fx8u*
>>   + maximum precision 32bit floating point tonemapping
>>   + forced FP32 processing
>>   + boosted malloc (experimental)
>>   + corrected & reworked JDD kernel
>
>> - ### **Known bugs:**
>>   - #### merge "bleed" in scenes where sun hits camera at an angle
>>   - #### zoom levels above 10x don't save final image
>

> ## :warning: Installation and requirements
> + OOS15 OnePlus13 (*tested on .821/.831 fws*)
>   + COS users can test & report back if mod works there
> + Magisk/KernelSU/APatch root

> ## :incoming_envelope: Support
> + [UCVM/OCVM telegram group](https://t.me/ucvm_gcam/24733)
