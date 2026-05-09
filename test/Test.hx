package;

import digigun.virt.libvirt.Connect;
import digigun.virt.libvirt.DomainCreateFlags;
import digigun.virt.libvirt.DomainListFlags;
import digigun.virt.libvirt.Error;
import digigun.virt.libvirt.Version;
import digigun.virt.libvirt.qemu.SessionDomain;

class Test {
    static public function main() {
        var conn = null;
        var writeConn = null;
        try {
            var version = Connect.getVersion();
            trace('libvirt version: ' + Version.toString(version));

            conn = Connect.openPreferred();
            trace('type=' + conn.getType());
            trace('uri=' + conn.getUri());
            trace('hostname=' + conn.getHostname());
            trace('alive=' + conn.isAlive());
            trace('secure=' + conn.isSecure());
            trace('encrypted=' + conn.isEncrypted());
            trace('libvirt=' + Version.toString(conn.getLibVirtVersion()));
            trace('hypervisor=' + Version.toString(conn.getHypervisorVersion()));

            var domains = conn.listAllDomains(DomainListFlags.Active | DomainListFlags.Inactive);
            trace('domains=' + domains.length);
            for (domain in domains) {
                try {
                    var state = domain.getState();
                    trace('domain name=' + domain.name + ' id=' + domain.id + ' state=' + state.state + ' reason=' + state.reason);
                } catch (error:Error) {
                    trace('Domain error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }

                try {
                    domain.close();
                } catch (error:Error) {
                    trace('Domain close error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
            }

            if (domains.length > 0) {
                var first = conn.lookupDomainByName(domains[0].name);
                try {
                    trace('lookupByName=' + first.name + ' id=' + first.id);
                    trace('lookupXmlLength=' + first.getXmlDesc().length);
                } catch (error:Error) {
                    trace('Lookup error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
                try {
                    first.close();
                } catch (error:Error) {
                    trace('Lookup close error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
            }

            if (Sys.getEnv("DIGIGUN_LIBVIRT_CREATE_XML_TEST") == "1") {
                writeConn = Connect.openPreferred(["test:///default"], false);
                var transientName = "digigun-libvirt-session-test";
                var transientXml = [
                    "<domain type='test'>",
                    "  <name>" + transientName + "</name>",
                    "  <memory unit='KiB'>1024</memory>",
                    "  <currentMemory unit='KiB'>1024</currentMemory>",
                    "  <vcpu>1</vcpu>",
                    "  <os>",
                    "    <type arch='x86_64'>hvm</type>",
                    "  </os>",
                    "</domain>"
                ].join("\n");

                var transient = writeConn.createDomainXml(transientXml, DomainCreateFlags.None);
                try {
                    trace("createXmlName=" + transient.name + " id=" + transient.id);
                    var transientState = transient.getState();
                    trace("createXmlState=" + transientState.state + " reason=" + transientState.reason);
                } catch (error:Error) {
                    trace('CreateXML error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
                try {
                    transient.destroy();
                } catch (error:Error) {
                    trace('CreateXML destroy error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
                try {
                    transient.close();
                } catch (error:Error) {
                    trace('CreateXML close error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                }
            }

            if (Sys.getEnv("DIGIGUN_LIBVIRT_QEMU_XML_TEST") == "1") {
                var qemuXml = SessionDomain.buildXml({
                    name: "digigun-qemu-session-sample",
                    memoryKiB: 262144,
                    vcpu: 1
                });
                trace("qemuXmlLength=" + qemuXml.length);

                var qemuDisk = Sys.getEnv("DIGIGUN_LIBVIRT_QEMU_DISK");
                var qemuKernel = Sys.getEnv("DIGIGUN_LIBVIRT_QEMU_KERNEL");

                if (qemuDisk != null || qemuKernel != null) {
                    var qemuConfig:digigun.virt.libvirt.qemu.SessionDomain.SessionDomainConfig = {
                        name: "digigun-qemu-session-sample",
                        memoryKiB: 262144,
                        vcpu: 1
                    };
                    if (qemuDisk != null) {
                        qemuConfig.disk = { path: qemuDisk };
                    }
                    if (qemuKernel != null) {
                        qemuConfig.kernelPath = qemuKernel;
                    }

                    writeConn = writeConn == null ? Connect.openPreferred(["qemu:///session"], false) : writeConn;
                    var qemuDomain = writeConn.createQemuSessionDomain(qemuConfig, DomainCreateFlags.None);
                    try {
                        trace("qemuCreateName=" + qemuDomain.name + " id=" + qemuDomain.id);
                    } catch (error:Error) {
                        trace('QEMU create error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
                    }
                    try {
                        qemuDomain.destroy();
                    } catch (_:Error) {}
                    try {
                        qemuDomain.close();
                    } catch (_:Error) {}
                }
            }

        } catch (error:Error) {
            trace('LibVirt error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
        }

        if (conn != null) {
            try {
                conn.close();
            } catch (error:Error) {
                trace('Connection close error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
            }
        }

        if (writeConn != null) {
            try {
                writeConn.close();
            } catch (error:Error) {
                trace('Write connection close error: ' + error.message + ' code=' + error.code + ' domain=' + error.domain);
            }
        }
    }
}
