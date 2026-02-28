
### **Driver Setup for Realtek RTL8851BU (LB-Link AX900)**

* **Hardware:** LB-Link BL-WDN951AX (AX900 + BT 5.3)
* **System:** Ubuntu 22.04 (Kernel 6.8+)
* **Driver Source:** [fofajardo/rtl8851bu](https://github.com/fofajardo/rtl8851bu)

#### **Step 1: Prerequisites**

```bash
sudo apt update
sudo apt install git build-essential dkms linux-headers-$(uname -r)

```

#### **Step 2: Firmware Installation**

The driver needs the "brain" file in the correct directory.

```bash
sudo mkdir -p /lib/firmware/rtw89/
sudo wget https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/rtw89/rtw8851b_fw.bin -O /lib/firmware/rtw89/rtw8851b_fw.bin

```

#### **Step 3: Compilation & Installation**

```bash
git clone https://github.com/fofajardo/rtl8851bu.git
cd rtl8851bu
make clean
make
sudo make install
sudo depmod -a
sudo modprobe 8851bu
```


#### 4. Persistent Configuration (DKMS)

To ensure the driver is automatically re-compiled whenever the Ubuntu kernel updates, we register it with the **Dynamic Kernel Module Support (DKMS)** framework.

```bash
cd ~/rtl8851bu
# 1. Create a directory for the source in the system's DKMS folder
sudo mkdir -p /usr/src/rtl8851bu-1.0

# 2. Copy the source files there
sudo cp -r . /usr/src/rtl8851bu-1.0

# 3. Add, build, and install via DKMS
sudo dkms add -m rtl8851bu -v 1.0
sudo dkms build -m rtl8851bu -v 1.0
sudo dkms install -m rtl8851bu -v 1.0

```
Now, every time you get a new kernel, Ubuntu will attempt to rebuild this for you in the background.




#### Step 5: The "Auto-Fix & Health Check" Script

The check script is located at `scripts/check-wifi.sh`. It checks if the interface is up; if not, it checks if the module exists, and if that fails, it re-compiles the driver.

**Make it executable and schedule it:**

```bash
chmod +x scripts/check-wifi.sh
```

#### Running it Automatically

To ensure your home lab is always connected, you can set this script to run every time the system boots.

1. **Open the Crontab editor:**
```bash
crontab -e

```


2. **Add this line at the bottom:**
```text
@reboot /home/omar/Home-Lab/scripts/check-wifi.sh >> /home/omar/wifi_log.txt 2>&1

```

