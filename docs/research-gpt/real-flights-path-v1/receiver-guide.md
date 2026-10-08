# Beginner receiver
All checks 2026-10-07. Nothing purchased or installed.

## Exact suggested parts [V hardware / A unquoted costs]
| Part | Specification | USD |
|---|---|---:|
| SDR | FlightAware Pro Stick Plus, USB-A, built-in 1090 MHz filter, SMA female | 45.99 V |
| Antenna | FlightAware 1090 MHz 26-inch 5.5 dBi antenna, N-type termination | 49.99 V |
| Computer | Raspberry Pi 4 Model B 2 GB, SC0193; use PiShop 2 GB Budget Kit with compatible case and supply | from 116.95 V listing; exact variant U |
| Storage | 32 GB microSD, A1/Class 10 | 12 A |
| RF cable | 3 m low-loss 50-ohm cable, N male antenna end → SMA male SDR end; confirm antenna connector sex | 25 A |
| Accessories | Ethernet cable, USB-A extension, USB microSD reader | 20 A |
Total: **$269.93 baseline A**, before tax/shipping. Roof mounting, grounding/surge protection or professional installation: separate quote U. Inventory is not guaranteed. Confirm kit variant price before ordering. [Pro Stick Plus](https://flightaware.store/products/pro-stick-plus); [FlightAware antenna](https://flightaware.store/collections/antenna/1090); [PiShop Pi4 kits](https://www.pishop.us/product-category/raspberry-pi/raspberry-pi-kits/pi-4-b-kits/).
Do not add a second 1090 filter by default. 978 MHz UAT requires separate compatible reception hardware; the launch BOM focuses on commercial 1090 aircraft.

## Plain-English Pi setup [A workflow based on verified guides]
1. Use a Mac/PC to install Raspberry Pi Imager. Insert the microSD in its reader.
2. Select the Pi 4 and the ADSB.im image under other special-purpose operating systems, or download its current Pi image and choose custom image. Confirm supported board and current instructions.
3. Write the card, eject it, put it in the Pi. Connect antenna to SDR, SDR to USB, Ethernet to router, then the correct Pi power supply.
4. Open http://adsb-feeder.local in your browser on the same network. Configure station location, time zone and SDR. Keep home coordinates private in the product.
5. Review the Data Sharing page; do not enable third-party feeds until their contribution terms are understood. Review MLAT location privacy—it is not enabled by default.
6. Check the local radar for plausible positions. Leave it running seven days; compare near-airport low traffic against high-altitude coverage by direction. Start indoors/attic, away from metal-coated glass; outdoor mounting is a later safe installation.
7. An engineer connects the decoder's local position output to WorldEngine's backend over an outbound authenticated connection. Never expose the raw home receiver publicly. Keep aggregator MLAT/returned data in a separate provenance stream.
Guides: [ADSB.im quick start](https://adsb.im/howto); [ADSB.im current interface](https://adsb.im/using).

## Existing Mac option
**V:** ADSB.im offers a VM image with SDR USB passthrough and reports MLAT issues. **A:** use the same SDR/antenna/cable, plus a USB-C adapter (~$15 if needed): **$140.98** baseline incremental hardware. Install a compatible virtualization tool, import the image, assign the SDR to the VM and open its browser setup. **U:** current Apple Silicon compatibility and hypervisor cost; verify before choosing this route. A dedicated Pi is the beginner recommendation; Mac sleep stops reception. [ADSB.im VM FAQ](https://adsb.im/faq).

## Denver coverage [A, not a site survey]
Planning range for airborne targets: indoor/window 20–80 nautical miles; favorable elevated outdoor installation 100–200 nm, potentially more. Front Range terrain can block western directions. Near-ground traffic has a much shorter horizon; buildings/terrain reduce it further. Do not infer Denver gate coverage from cruise-altitude coverage.
Illustrative geometric horizon: d[km]≈3.57(√h_receiver[m]+√h_aircraft[m]), heights above local terrain. At 10 m receiver height and 10,000 m aircraft height: ~368 km /199 nm; at 300 m: ~73 km /39 nm; at 5 m: ~19 km /10 nm. This is an ideal geometric upper bound, not reception prediction; atmospheric refraction changes it. Range assumptions require actual measurement.
**A:** 8 W station, 730 h/month and $0.15/kWh → ~$0.88/month electricity. Household tariff is not verified.
