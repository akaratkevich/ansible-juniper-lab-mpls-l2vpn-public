# ansible-juniper-lab-mpls-l2vpn-public

This example shows how to configure and validate an MPLS-based Layer 2 VPN across simplified provider network running Junos to interconnect customer sites with Layer 2 connectivity. Layer 2 VPNs give customers complete control over their choice of transport and routing protocols transparent to the provider core network.

The lab consists of 3x Juniper [vMX](https://containerlab.dev/manual/kinds/vr-vmx/) nodes and 2x [FRR](https://docs.frrouting.org/en/latest/overview.html) nodes

Although this lab is predominantly around Junos with Ansible, FRR has been chosen as an open-source IP routing protocol suite for Linux and Unix platforms to allow further emulate network configurations and protocols, including OSPF, BGP, RIP, ISIS, and more on the CE's with low impact on host resources. 

[Containerlab](https://containerlab.dev/) is used as tool for provisioning this network lab.
*--- Containerlab, Ansible and Docker setup and images are not included ---*

## IP Addressing

Containerlab management network: 172.100.1.0/24

`ce1`: 
	192.168.0.1/30 - to `ce2`(over L2VPN)
`ce2`:
	192.168.0.2/30 - to `ce1` (over L2VPN)
`pe1`: 
	10.0.0.1/30 - to `p1`
	10.1.1.1/32 - lo0 
`pe2`:
	10.0.0.6/30 - to `p1`
	10.2.2.2/32 - lo0
`p1`:
	10.0.0.2/30 - to `pe1`
	10.0.0.5/30 - to `pe2`
	10.3.3.3/32 - lo0


## Containerlab

Docker images used in this lab:
	- vrnetlab/vr-vmx:22.3R1.11
	- frrouting/frr:latest


Lab topology:

<mark style="background: #ADCCFFA6;">clab/topology.yml</mark>
```
name: automatedNetwork/Configure MPLS-Based Layer 2 VPNs
prefix: ""
# containerlab topology for the lab

mgmt:
  network: lab_1
  ipv4-subnet: 172.100.1.0/24

topology:
  kinds:
    vr-vmx:
      image: vrnetlab/vr-vmx:22.3R1.11
    linux:
      image: frrouting/frr:latest

  nodes:
    ce1:
      kind: linux
      mgmt-ipv4: 172.100.1.2
      binds:
        - router1/daemons:/etc/frr/daemons
        - router1/vtysh.conf:/etc/frr/vtysh.conf
        - router1/frr.conf:/etc/frr/frr.conf

    ce2:
      kind: linux
      mgmt-ipv4: 172.100.1.3
      binds:
        - router2/daemons:/etc/frr/daemons
        - router2/vtysh.conf:/etc/frr/vtysh.conf
        - router2/frr.conf:/etc/frr/frr.conf

    pe1:
      kind: vr-vmx
      mgmt-ipv4: 172.100.1.4

    pe2:
      kind: vr-vmx
      mgmt-ipv4: 172.100.1.5

    p1:
      kind: vr-vmx
      mgmt-ipv4: 172.100.1.6  

  # Define links (interconnections)
  links:
    - endpoints: ["ce1:eth1", "pe1:eth1"]
    - endpoints: ["pe1:eth2", "p1:eth1"]
    - endpoints: ["pe2:eth2", "p1:eth2"]  
    - endpoints: ["pe2:eth1", "ce2:eth1"]
```


## Deploying the lab

1. Clone the lab into the local directory on the host:
```
git clone https://github.com/akaratkevich/ansible-juniper-lab-mpls-l2vpn-public.git
```

2. Navigate into <mark style="background: #CACFD9A6;">~/ansible-juniper-lab-mpls-l2vpn-public$ </mark>


```
make
```


<mark style="background: #BBFABBA6;">Results:</mark>
```
anton@mcc:~/git_hub/ansible-juniper-lab-mpls-l2vpn-public$ make
Executing playbook to deploy topology
Enter the sudo password: 

PLAY [Deploy containerlab topology] ************************************************************************************************************************************************************************************************

TASK [Run clab deploy command] *****************************************************************************************************************************************************************************************************
changed: [localhost]

TASK [Wait for the deployment to complete] *****************************************************************************************************************************************************************************************
Pausing for 180 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [localhost]

TASK [Check Docker containers status] **********************************************************************************************************************************************************************************************
changed: [localhost]

TASK [Check for healthy status] ****************************************************************************************************************************************************************************************************
ok: [localhost] => {
    "msg": "All containers are healthy"
}

PLAY RECAP *************************************************************************************************************************************************************************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

Waiting 10 seconds before running script
Executing script to enable ssh/rsa auth on the nodes
spawn ./scripts/deploy-conf-file -config ./configuration/sshRSA.cfg
Enter the Juniper nodes (IP addresses or hostnames):seperated by comma
pe1,pe2,p1
Successfully executed configuration on pe1
Successfully executed configuration on pe2
Successfully executed configuration on p1
Waiting 3 seconds before deploying config
Running playbook to configure nodes
[WARNING]: Invalid characters were found in group names but not replaced, use -vvvv to see details

PLAY [Load and commit base configuration] ******************************************************************************************************************************************************************************************

TASK [Load configuration from a local file and commit] *****************************************************************************************************************************************************************************
changed: [p1]
changed: [pe1]
changed: [pe2]

TASK [Print the response] **********************************************************************************************************************************************************************************************************
ok: [pe1] => {
    "response": {
        "changed": true,
        "diff": {
            "prepared": "\n[edit interfaces]\n+   ge-0/0/0 {\n+       description \"Link from PE1 to CE1\";\n+       encapsulation ethernet-ccc;\n+       unit 0 {\n+           family ccc;\n+       }\n+   }\n+   ge-0/0/1 {\n+       description \"Link from PE1 to P-router\";\n+       mtu 4000;\n+       unit 0 {\n+           family inet {\n+               address 10.0.0.1/30;\n+           }\n+           family mpls;\n+       }\n+   }\n+   lo0 {\n+       unit 0 {\n+           family inet {\n+               address 1.1.1.1/32;\n+           }\n+       }\n+   }\n[edit routing-instances]\n+   l2vpn1 {\n+       instance-type l2vpn;\n+       protocols {\n+           l2vpn {\n+               interface ge-0/0/0.0 {\n+                   description \"EDGE LINK BETWEEN PE1 AND CE1\";\n+               }\n+               site CE-1 {\n+                   interface ge-0/0/0.0 {\n+                       remote-site-id 2;\n+                   }\n+                   site-identifier 1;\n+               }\n+               encapsulation-type ethernet;\n+           }\n+       }\n+       interface ge-0/0/0.0;\n+       route-distinguisher 1.1.1.1:1;\n+       vrf-target target:65412:1;\n+   }\n[edit]\n+  routing-options {\n+      autonomous-system 65412;\n+  }\n+  protocols {\n+      bgp {\n+          group ibgp {\n+              type internal;\n+              local-address 1.1.1.1;\n+              family l2vpn {\n+                  signaling;\n+              }\n+              neighbor 2.2.2.2;\n+          }\n+      }\n+      mpls {\n+          label-switched-path lsp_to_pe2 {\n+              to 2.2.2.2;\n+          }\n+          interface ge-0/0/1.0;\n+      }\n+      ospf {\n+          traffic-engineering;\n+          area 0.0.0.0 {\n+              interface lo0.0;\n+              interface ge-0/0/1.0;\n+          }\n+      }\n+      rsvp {\n+          interface lo0.0;\n+          interface ge-0/0/1.0;\n+      }\n+  }\n"
        },
        "diff_lines": [
            "",
            "[edit interfaces]",
            "+   ge-0/0/0 {",
            "+       description \"Link from PE1 to CE1\";",
            "+       encapsulation ethernet-ccc;",
            "+       unit 0 {",
            "+           family ccc;",
            "+       }",
            "+   }",
            "+   ge-0/0/1 {",
            "+       description \"Link from PE1 to P-router\";",
            "+       mtu 4000;",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 10.0.0.1/30;",
            "+           }",
            "+           family mpls;",
            "+       }",
            "+   }",
            "+   lo0 {",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 1.1.1.1/32;",
            "+           }",
            "+       }",
            "+   }",
            "[edit routing-instances]",
            "+   l2vpn1 {",
            "+       instance-type l2vpn;",
            "+       protocols {",
            "+           l2vpn {",
            "+               interface ge-0/0/0.0 {",
            "+                   description \"EDGE LINK BETWEEN PE1 AND CE1\";",
            "+               }",
            "+               site CE-1 {",
            "+                   interface ge-0/0/0.0 {",
            "+                       remote-site-id 2;",
            "+                   }",
            "+                   site-identifier 1;",
            "+               }",
            "+               encapsulation-type ethernet;",
            "+           }",
            "+       }",
            "+       interface ge-0/0/0.0;",
            "+       route-distinguisher 1.1.1.1:1;",
            "+       vrf-target target:65412:1;",
            "+   }",
            "[edit]",
            "+  routing-options {",
            "+      autonomous-system 65412;",
            "+  }",
            "+  protocols {",
            "+      bgp {",
            "+          group ibgp {",
            "+              type internal;",
            "+              local-address 1.1.1.1;",
            "+              family l2vpn {",
            "+                  signaling;",
            "+              }",
            "+              neighbor 2.2.2.2;",
            "+          }",
            "+      }",
            "+      mpls {",
            "+          label-switched-path lsp_to_pe2 {",
            "+              to 2.2.2.2;",
            "+          }",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+      ospf {",
            "+          traffic-engineering;",
            "+          area 0.0.0.0 {",
            "+              interface lo0.0;",
            "+              interface ge-0/0/1.0;",
            "+          }",
            "+      }",
            "+      rsvp {",
            "+          interface lo0.0;",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+  }"
        ],
        "failed": false,
        "file": "./configuration/pe1.txt",
        "msg": "Configuration has been: opened, loaded, checked, diffed, committed, closed."
    }
}
ok: [pe2] => {
    "response": {
        "changed": true,
        "diff": {
            "prepared": "\n[edit interfaces]\n+   ge-0/0/0 {\n+       description \"Link from PE2 to CE2\";\n+       encapsulation ethernet-ccc;\n+       unit 0 {\n+           family ccc;\n+       }\n+   }\n+   ge-0/0/1 {\n+       description \"Link from PE2 to P-router\";\n+       mtu 4000;\n+       unit 0 {\n+           family inet {\n+               address 10.0.0.6/30;\n+           }\n+           family mpls;\n+       }\n+   }\n+   lo0 {\n+       unit 0 {\n+           family inet {\n+               address 2.2.2.2/32;\n+           }\n+       }\n+   }\n[edit routing-instances]\n+   l2vpn1 {\n+       instance-type l2vpn;\n+       protocols {\n+           l2vpn {\n+               interface ge-0/0/0.0 {\n+                   description \"EDGE LINK BETWEEN PE2 AND CE2\";\n+               }\n+               site CE-2 {\n+                   interface ge-0/0/0.0 {\n+                       remote-site-id 1;\n+                   }\n+                   site-identifier 2;\n+               }\n+               encapsulation-type ethernet;\n+           }\n+       }\n+       interface ge-0/0/0.0;\n+       route-distinguisher 2.2.2.2:2;\n+       vrf-target target:65412:1;\n+   }\n[edit]\n+  routing-options {\n+      autonomous-system 65412;\n+  }\n+  protocols {\n+      bgp {\n+          group ibgp {\n+              type internal;\n+              local-address 2.2.2.2;\n+              family l2vpn {\n+                  signaling;\n+              }\n+              neighbor 1.1.1.1;\n+          }\n+      }\n+      mpls {\n+          label-switched-path lsp_to_pe1 {\n+              to 1.1.1.1;\n+          }\n+          interface ge-0/0/1.0;\n+      }\n+      ospf {\n+          traffic-engineering;\n+          area 0.0.0.0 {\n+              interface lo0.0;\n+              interface ge-0/0/1.0;\n+          }\n+      }\n+      rsvp {\n+          interface lo0.0;\n+          interface ge-0/0/1.0;\n+      }\n+  }\n"
        },
        "diff_lines": [
            "",
            "[edit interfaces]",
            "+   ge-0/0/0 {",
            "+       description \"Link from PE2 to CE2\";",
            "+       encapsulation ethernet-ccc;",
            "+       unit 0 {",
            "+           family ccc;",
            "+       }",
            "+   }",
            "+   ge-0/0/1 {",
            "+       description \"Link from PE2 to P-router\";",
            "+       mtu 4000;",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 10.0.0.6/30;",
            "+           }",
            "+           family mpls;",
            "+       }",
            "+   }",
            "+   lo0 {",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 2.2.2.2/32;",
            "+           }",
            "+       }",
            "+   }",
            "[edit routing-instances]",
            "+   l2vpn1 {",
            "+       instance-type l2vpn;",
            "+       protocols {",
            "+           l2vpn {",
            "+               interface ge-0/0/0.0 {",
            "+                   description \"EDGE LINK BETWEEN PE2 AND CE2\";",
            "+               }",
            "+               site CE-2 {",
            "+                   interface ge-0/0/0.0 {",
            "+                       remote-site-id 1;",
            "+                   }",
            "+                   site-identifier 2;",
            "+               }",
            "+               encapsulation-type ethernet;",
            "+           }",
            "+       }",
            "+       interface ge-0/0/0.0;",
            "+       route-distinguisher 2.2.2.2:2;",
            "+       vrf-target target:65412:1;",
            "+   }",
            "[edit]",
            "+  routing-options {",
            "+      autonomous-system 65412;",
            "+  }",
            "+  protocols {",
            "+      bgp {",
            "+          group ibgp {",
            "+              type internal;",
            "+              local-address 2.2.2.2;",
            "+              family l2vpn {",
            "+                  signaling;",
            "+              }",
            "+              neighbor 1.1.1.1;",
            "+          }",
            "+      }",
            "+      mpls {",
            "+          label-switched-path lsp_to_pe1 {",
            "+              to 1.1.1.1;",
            "+          }",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+      ospf {",
            "+          traffic-engineering;",
            "+          area 0.0.0.0 {",
            "+              interface lo0.0;",
            "+              interface ge-0/0/1.0;",
            "+          }",
            "+      }",
            "+      rsvp {",
            "+          interface lo0.0;",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+  }"
        ],
        "failed": false,
        "file": "./configuration/pe2.txt",
        "msg": "Configuration has been: opened, loaded, checked, diffed, committed, closed."
    }
}
ok: [p1] => {
    "response": {
        "changed": true,
        "diff": {
            "prepared": "\n[edit interfaces]\n+   ge-0/0/0 {\n+       description \"Link from P-router to PE1\";\n+       mtu 4000;\n+       unit 0 {\n+           family inet {\n+               address 10.0.0.2/30;\n+           }\n+           family mpls;\n+       }\n+   }\n+   ge-0/0/1 {\n+       description \"Link from P-router to PE2\";\n+       mtu 4000;\n+       unit 0 {\n+           family inet {\n+               address 10.0.0.5/30;\n+           }\n+           family mpls;\n+       }\n+   }\n+   lo0 {\n+       unit 0 {\n+           family inet {\n+               address 3.3.3.3/32;\n+           }\n+       }\n+   }\n[edit]\n+  protocols {\n+      mpls {\n+          interface ge-0/0/0.0;\n+          interface ge-0/0/1.0;\n+      }\n+      ospf {\n+          traffic-engineering;\n+          area 0.0.0.0 {\n+              interface lo0.0;\n+              interface ge-0/0/0.0;\n+              interface ge-0/0/1.0;\n+          }\n+      }\n+      rsvp {\n+          interface lo0.0;\n+          interface ge-0/0/0.0;\n+          interface ge-0/0/1.0;\n+      }\n+  }\n"
        },
        "diff_lines": [
            "",
            "[edit interfaces]",
            "+   ge-0/0/0 {",
            "+       description \"Link from P-router to PE1\";",
            "+       mtu 4000;",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 10.0.0.2/30;",
            "+           }",
            "+           family mpls;",
            "+       }",
            "+   }",
            "+   ge-0/0/1 {",
            "+       description \"Link from P-router to PE2\";",
            "+       mtu 4000;",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 10.0.0.5/30;",
            "+           }",
            "+           family mpls;",
            "+       }",
            "+   }",
            "+   lo0 {",
            "+       unit 0 {",
            "+           family inet {",
            "+               address 3.3.3.3/32;",
            "+           }",
            "+       }",
            "+   }",
            "[edit]",
            "+  protocols {",
            "+      mpls {",
            "+          interface ge-0/0/0.0;",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+      ospf {",
            "+          traffic-engineering;",
            "+          area 0.0.0.0 {",
            "+              interface lo0.0;",
            "+              interface ge-0/0/0.0;",
            "+              interface ge-0/0/1.0;",
            "+          }",
            "+      }",
            "+      rsvp {",
            "+          interface lo0.0;",
            "+          interface ge-0/0/0.0;",
            "+          interface ge-0/0/1.0;",
            "+      }",
            "+  }"
        ],
        "failed": false,
        "file": "./configuration/p1.txt",
        "msg": "Configuration has been: opened, loaded, checked, diffed, committed, closed."
    }
}

PLAY RECAP *************************************************************************************************************************************************************************************************************************
p1                         : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
pe1                        : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
pe2                        : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

<mark style="background: #BBFABBA6;">Checking:</mark> L3 between `ce1` and `ce2`
```
anton@mcc:~/git_hub/ansible-juniper-lab-mpls-l2vpn-public$ sudo docker exec -it ce1 vtysh

Hello, this is FRRouting (version 8.4_git).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

ce1# ping 192.168.0.2
PING 192.168.0.2 (192.168.0.2): 56 data bytes
64 bytes from 192.168.0.2: seq=0 ttl=64 time=3.189 ms
64 bytes from 192.168.0.2: seq=1 ttl=64 time=1.448 ms
64 bytes from 192.168.0.2: seq=2 ttl=64 time=1.788 ms
64 bytes from 192.168.0.2: seq=3 ttl=64 time=1.623 ms
^C
--- 192.168.0.2 ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 1.448/2.012/3.189 ms
```


### Step-by-step

Below is explanation of how the lab was deployed:

Makefile first executes ansible-playbook '<mark style="background: #ADCCFFA6;">deploy-clab-topology.yml</mark>'

```
---
- name: Deploy containerlab topology
  hosts: localhost
  gather_facts: false
  become: true
  vars_prompt:
    - name: ansible_become_password
      prompt: "Enter the sudo password"
      private: yes

  tasks:
    - name: Run clab deploy command
      ansible.builtin.shell: "sudo -S clab deploy -t /home/anton/git_hub/ansible-juniper-lab-mpls-l2vpn-public/clab/topology.yml"
      environment:
        SUDO_PASS: "{{ ansible_become_password }}"
          #no_log: true

    - name: Wait for the deployment to complete
      pause:
        minutes: 3

    - name: Check Docker containers status
      ansible.builtin.shell: "docker ps -a"
      register: docker_ps_output

    - name: Check for healthy status
      ansible.builtin.debug:
        msg: "All containers are healthy"
      when: "'(healthy)' in docker_ps_output.stdout"
```
 
It then deploys SSH RSA config onto the 3x vr-vmx nodes:
Sample of the required Junos configuration:
<mark style="background: #ADCCFFA6;">sshRSA.cfg</mark>
```
configure
set system login user anton uid 2001
set system login user anton class super-user
set system login user anton authentication ssh-rsa "ssh-rsa -- insert your key here --anton@mcc"
commit and-quit
```

In one of my other [labs](https://github.com/akaratkevich/ansible-juniper-lab-01-public) I demonstrated a Go script that pushes this configuration file over to the required nodes.

Because this script expects input from the user (ie `pe1,pe2,p1`) I'm executing this Go script using [expect](https://linux.die.net/man/1/expect) script to pass those otherwise manually provided variables - *obviously in a real world it would have been easier to modify the Go script but its all about experimenting :)
<mark style="background: #ADCCFFA6;">expect.exp</mark>
```
#!/usr/bin/expect -f

set timeout -1

spawn ./scripts/deploy-conf-file -config ./configuration/sshRSA.cfg

expect "Enter the Juniper nodes (IP addresses or hostnames):seperated by comma"

send -- "pe1,pe2,p1\r"

expect eof
```

Finally Makefile executes another ansible-playbook to deploy configuration files to the nodes: 

<mark style="background: #ADCCFFA6;">conf-files.yml</mark>
```
---
- name: Load and commit base configuration
  hosts: vr-vmx
  gather_facts: false
  connection: local

  roles:
    - Juniper.junos
  tasks:
    - name: Load configuration from a local file and commit
      juniper_junos_config:
        load: merge
        format: set
        src: "./configuration/{{ inventory_hostname.split('.')[0] }}.txt"
      register: response

    - name: Print the response
      debug:
        var: response
```

I have not templated the configuration in this lab yet, but something to consider.

FRR configuration is located in these files:
```
ansible-juniper-lab-mpls-l2vpn-public/clab$ tree 
.
├── router1
│   ├── daemons
│   ├── frr.conf
│   └── vtysh.conf
├── router2
│   ├── daemons
│   ├── frr.conf
│   └── vtysh.conf
└── topology.yml

2 directories, 7 files
```

