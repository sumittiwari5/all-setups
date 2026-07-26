# Understanding RAM, OOM Killer, and Swap Space on an EC2 Instance

When running multiple applications on an EC2 instance, it's important to understand how **RAM**, the **OOM Killer**, and **Swap Space** work together. This guide explains each concept in simple terms and shows how to create swap space on a Linux EC2 instance.

---

## 🖥️ Your EC2 Instance Has Limited RAM

Every EC2 instance comes with a fixed amount of physical memory (RAM).

For example:

| EC2 Instance | RAM |
|--------------|-----|
| `t3.medium` | **4 GB** |

Every application running on the instance consumes some of this RAM:

- MySQL
- Java/Spring Boot applications
- Maven during compilation
- Docker containers
- Linux operating system itself

Think of RAM like your **work desk**.

- The larger the desk, the more papers you can spread out.
- Once the desk is completely full, there's nowhere left to put new papers.

---

# ❌ What Happens When RAM Runs Out?

Suppose your instance has only **4 GB RAM**, and you're trying to run:

- MySQL
- Three Spring Boot services
- Maven building all of them
- Docker Compose

All of these compete for the same memory.

When Linux completely runs out of RAM, it doesn't politely ask applications to stop.

Instead, it immediately kills one process to free memory.

This mechanism is called the **OOM Killer**.

> **OOM = Out Of Memory**

There is:

- ❌ No warning
- ❌ No graceful shutdown
- ❌ No opportunity to save work

Linux simply terminates whichever process it believes should die.

As a result, you may observe:

- Random Maven build failures
- Docker containers suddenly exiting
- Spring Boot compilation stopping midway
- `docker compose up` failing without an obvious memory-related error

The root cause is often **insufficient RAM**, even though the error message doesn't explicitly mention memory.

---

# 💡 What Is Swap Space?

Swap space is a portion of your **hard disk (EBS volume)** that Linux can temporarily use as **overflow memory** when RAM becomes full.

It is **not** actual RAM.

It is **much slower** than RAM because disk storage is significantly slower than physical memory.

However, it is far better than having Linux terminate your applications.

---

## 📚 Analogy

Imagine your desk is completely full.

Instead of throwing papers away, you place some of them into a nearby drawer.

- **Desk** → RAM
- **Drawer** → Swap

Accessing papers in the drawer is slower than grabbing them from your desk, but nothing gets lost.

That's exactly how swap works.

---

# Creating Swap Space

## Step 1 — Create a 2 GB Swap File

```bash
sudo fallocate -l 2G /swapfile
```

### What this does

Creates a file named:

```
/swapfile
```

with a size of **2 GB**.

At this point:

- the file exists
- disk space is reserved
- Linux is **not** using it as swap yet

---

## Step 2 — Secure the Swap File

```bash
sudo chmod 600 /swapfile
```

### What this does

Changes file permissions so that **only the root user** can access it.

Why?

Swap may temporarily contain:

- passwords
- application memory
- sensitive information

Restricting permissions prevents other users from reading those contents.

---

## Step 3 — Format the File as Swap

```bash
sudo mkswap /swapfile
```

### What this does

Formats the file so Linux recognizes it as **swap space**.

Before this command:

```
/swapfile
```

is simply a normal file.

After this command:

Linux understands that this file is intended for swap.

---

## Step 4 — Enable Swap

```bash
sudo swapon /swapfile
```

### What this does

Immediately activates the swap file.

From this point onward:

- Linux can use it whenever RAM becomes full.
- The swap space becomes part of the system's available memory.

---

## Step 5 — Make Swap Permanent

```bash
echo '/swapfile swap swap defaults 0 0' | sudo tee -a /etc/fstab
```

### Why is this needed?

Without this step:

- the swap file still exists
- but after every reboot it becomes **disabled**

Linux reads the file:

```
/etc/fstab
```

during startup.

Adding the above line tells Linux:

> Every time the system boots, automatically enable `/swapfile` as swap.

Without this entry, you would need to manually execute:

```bash
sudo swapon /swapfile
```

after every reboot.

---

# Verify That Swap Is Working

Run:

```bash
free -h
```

Example output:

```text
               total        used        free      shared  buff/cache   available
Mem:           3.8Gi       2.4Gi       300Mi       120Mi       1.1Gi       1.0Gi
Swap:          2.0Gi         0Bi       2.0Gi
```

If the **Swap** row shows:

```
2.0Gi
```

then your swap space has been successfully enabled.

---

# Important Notes

### ✅ Swap is a safety net

Swap helps prevent applications from crashing when RAM is exhausted.

It is **not** a performance upgrade.

---

### ⚠️ Swap is slower than RAM

Because swap resides on disk, accessing it is much slower than accessing physical memory.

Heavy swap usage can noticeably slow down your applications and builds.

---

### 📦 2 GB Is a Good Starting Point

For many small development environments, a **2 GB** swap file provides enough additional buffer to prevent unexpected crashes.

If your system still frequently runs out of memory, the proper solution is usually to upgrade to an EC2 instance with more RAM rather than continuously increasing swap size.

---

### 💾 Swap Uses Disk Space

A 2 GB swap file consumes **2 GB of your EBS storage**.

While this is generally inexpensive, it's worth remembering that swap uses disk capacity.

---

# Summary

| Component | Purpose |
|-----------|---------|
| **RAM** | Fast memory used by running applications |
| **OOM Killer** | Linux mechanism that kills processes when RAM is exhausted |
| **Swap Space** | Disk-based overflow memory used when RAM becomes full |
| **`fallocate`** | Creates a swap file |
| **`chmod 600`** | Secures the swap file |
| **`mkswap`** | Formats the file as swap |
| **`swapon`** | Activates swap immediately |
| **`/etc/fstab`** | Automatically enables swap after every reboot |
| **`free -h`** | Displays RAM and swap usage |

---

## Final Takeaway

Swap is best viewed as an **emergency backup**, not additional RAM.

It helps prevent the Linux **OOM Killer** from abruptly terminating your applications during memory-intensive workloads such as building multiple Spring Boot services with Maven while running Docker and MySQL.

If your instance regularly relies heavily on swap, consider upgrading to an EC2 instance with more RAM for better performance and stability.
