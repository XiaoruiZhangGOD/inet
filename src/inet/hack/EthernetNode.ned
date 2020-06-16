//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

package inet.hack;

import inet.applications.contract.IApp;
import inet.common.MessageDispatcher;
import inet.linklayer.contract.IEthernetInterface;
import inet.linklayer.contract.IMacAddressTable;
import inet.linklayer.ethernet.switch.MacRelayUnit;
import inet.networklayer.common.InterfaceEntry;
import inet.networklayer.common.InterfaceTable;
import inet.networklayer.ipv4.Ipv4NetworkLayer;
import inet.protocol.common.InterPacketGap;
import inet.protocol.common.ProtocolChecker;
import inet.protocol.ethernet.IEthernetMacLayer;
import inet.protocol.ethernet.IEthernetPhyLayer;
import inet.protocol.ieee8021q.IIeee8021qChecker;
import inet.protocol.ieee8021q.IIeee8021qInserter;
import inet.protocol.ieee8022.IIeee8022LlcChecker;
import inet.protocol.ieee8022.IIeee8022LlcInserter;
import inet.protocol.ieee8022.IIeee8022SnapChecker;
import inet.protocol.ieee8022.IIeee8022SnapInserter;
import inet.protocol.transceiver.PreemptibleTransmitter;
import inet.protocol.transceiver.StreamingReceiver;
import inet.queueing.base.PacketProcessorBase;
import inet.queueing.common.PacketMultiplexer;
import inet.queueing.contract.IPacketClassifier;
import inet.queueing.contract.IPacketFilter;
import inet.queueing.contract.IPacketFlow;
import inet.queueing.contract.IPacketQueue;
import inet.queueing.contract.IPacketServer;
import inet.transportlayer.udp.Udp;

module EthernetPhyLayer like IEthernetPhyLayer
{
    parameters:
        volatile double bitrate @unit(bps);
        outboundEmitter.signalName = "packetSentToLower";
        outboundEmitter.direction = "outbound";
        outboundEmitter.protocolName = "ethernetphy";
        inboundEmitter.signalName = "packetReceivedFromLower";
        inboundEmitter.direction = "inbound";
        inboundEmitter.protocolName = "ethernetphy";
        *.bitrate = default(bitrate);
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        preambleInserter: <default("EthernetPreambleInserter")> like IPacketFlow {
            @display("p=200,100");
        }
        interFrameGapInserter: InterPacketGap {
            duration = default(96s / dropUnit(bitrate));
            @display("p=200,200");
        }
        outboundEmitter: <default("PacketEmitter")> like IPacketFlow {
            @display("p=200,300");
        }
        transmitter: PreemptibleTransmitter {
            datarate = default(bitrate);
            @display("p=200,400");
        }
        preambleChecker: <default("EthernetPreambleChecker")> like IPacketFilter {
            @display("p=500,100");
        }
        inboundEmitter: <default("PacketEmitter")> like IPacketFlow {
            @display("p=500,300");
        }
        receiver: StreamingReceiver {
            datarate = default(bitrate);
            @display("p=500,400");
        }
    connections:
        upperLayerIn --> { @display("m=n"); } --> preambleInserter.in;
        preambleInserter.out --> interFrameGapInserter.in;
        interFrameGapInserter.out --> outboundEmitter.in;
        outboundEmitter.out --> transmitter.in;
        transmitter.out --> { @display("m=s"); } --> lowerLayerOut;

        lowerLayerIn --> { @display("m=s"); } --> receiver.in;
        receiver.out --> inboundEmitter.in;
        inboundEmitter.out --> preambleChecker.in;
        preambleChecker.out --> { @display("m=n"); } --> upperLayerOut;
}

simple EthernetCutthroughLayer extends PacketProcessorBase
{
    parameters:
        @class(EthernetCutthroughLayer);
        @display("i=block/routing");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
        input cutthroughIn;
        output cutthroughOut;
}

module EthernetMacLayer like IEthernetMacLayer
{
    parameters:
        outboundEmitter.signalName = "packetSentToLower";
        outboundEmitter.direction = "outbound";
        outboundEmitter.protocolName = "ethernetmac";
        inboundEmitter.signalName = "packetReceivedFromLower";
        inboundEmitter.direction = "inbound";
        inboundEmitter.protocolName = "ethernetmac";
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        queue: <default("PacketQueue")> like IPacketQueue {
            @display("p=200,100");
        }
        server: <default("InstantServer")> like IPacketServer {
            @display("p=200,200");
        }
        streamer: <default("OmittedPacketFlow")> like IPacketFlow {
            @display("p=200,300");
        }
        fcsInserter: <default("EthernetFcsInserter")> like IPacketFlow {
            @display("p=200,400");
        }
        outboundEmitter: <default("PacketEmitter")> like IPacketFlow {
            @display("p=200,500");
        }
        fcsChecker: <default("EthernetFcsChecker")> like IPacketFilter {
            @display("p=500,400");
        }
        inboundEmitter: <default("PacketEmitter")> like IPacketFlow {
            @display("p=500,500");
        }
    connections:
        upperLayerIn --> { @display("m=n"); } --> queue.in;
        queue.out --> server.in;
        server.out --> streamer.in;
        streamer.out --> fcsInserter.in;
        fcsInserter.out --> outboundEmitter.in;
        outboundEmitter.out --> { @display("m=s"); } --> lowerLayerOut;

        lowerLayerIn --> { @display("m=s"); } --> inboundEmitter.in;
        inboundEmitter.out --> fcsChecker.in;
        fcsChecker.out --> { @display("m=n"); } --> upperLayerOut;
}

module HostEthernetInterface extends InterfaceEntry like IEthernetInterface
{
    parameters:
        bool broadcast = default(true);
        bool multicast = default(true);
        string address = default("auto");
        double bitrate @unit(bps);
        string interfaceTableModule;
        *.bitrate = default(bitrate);
        @class(InterfaceEntry);
        @display("i=block/ifcard;bgb=700,300");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        inout phys;
    submodules:
        macLayer: EthernetMacLayer {
            @display("p=500,100");
        }
        phyLayer: EthernetPhyLayer {
            @display("p=500,200");
        }
    connections:
        upperLayerIn --> { @display("m=n"); } --> macLayer.upperLayerIn;
        macLayer.lowerLayerOut --> phyLayer.upperLayerIn;
        phyLayer.lowerLayerOut --> { @display("m=s"); } --> phys$o;

        phys$i --> { @display("m=s"); } --> phyLayer.lowerLayerIn;
        phyLayer.upperLayerOut --> macLayer.lowerLayerIn;
        macLayer.upperLayerOut --> { @display("m=n"); } --> upperLayerOut;
}

module SwitchEthernetInterface extends InterfaceEntry like IEthernetInterface
{
    parameters:
        bool broadcast = default(true);
        bool multicast = default(true);
        string address = default("auto");
        double bitrate @unit(bps);
        string interfaceTableModule;
        *.bitrate = default(bitrate);
        @class(InterfaceEntry);
        @display("i=block/ifcard;bgb=700,400");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input cutthroughIn;
        output cutthroughOut;
        inout phys;
    submodules:
        macLayer: EthernetMacLayer {
            @display("p=500,100");
        }
        cutthrough: EthernetCutthroughLayer {
            @display("p=500,200");
        }
        phyLayer: EthernetPhyLayer {
            @display("p=500,300");
        }
    connections:
        upperLayerIn --> { @display("m=n"); } --> macLayer.upperLayerIn;
        macLayer.lowerLayerOut --> cutthrough.upperLayerIn;
        cutthrough.lowerLayerOut --> phyLayer.upperLayerIn;
        phyLayer.lowerLayerOut --> { @display("m=s"); } --> phys$o;

        phys$i --> { @display("m=s"); } --> phyLayer.lowerLayerIn;
        phyLayer.upperLayerOut --> cutthrough.lowerLayerIn;
        cutthrough.upperLayerOut --> macLayer.lowerLayerIn;
        macLayer.upperLayerOut --> { @display("m=n"); } --> upperLayerOut;

        cutthrough.cutthroughOut --> { @display("m=e"); } --> cutthroughOut;
        cutthroughIn --> { @display("m=e"); } --> cutthrough.cutthroughIn;
}

simple EthernetRelay
{
    parameters:
        @display("i=block/switch");
    gates:
        input lowerLayerIn;
        output lowerLayerOut;
        input upperLayerIn;
        output upperLayerOut;
}

module SimpleEthernetLayer
{
    parameters:
        string interfaceTableModule;
        *.interfaceTableModule = default(interfaceTableModule);
        paddingInserter.minLength = default(60B);
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        typeOrLengthInserter: <default("EthernetTypeOrLengthInserter")> like IPacketFlow {
            @display("p=200,100");
        }
        addressInserter: <default("EthernetAddressInserter")> like IPacketFlow {
            @display("p=200,200");
        }
        paddingInserter: <default("PaddingInserter")> like IPacketFlow {
            @display("p=200,300");
        }
        typeOrLengthChecker: <default("EthernetTypeOrLengthChecker")> like IPacketFilter {
            @display("p=700,100");
        }
        addressChecker: <default("EthernetAddressChecker")> like IPacketFilter {
            @display("p=700,200");
        }
    connections:
        addressInserter.out --> paddingInserter.in;
        typeOrLengthInserter.out --> addressInserter.in;
        typeOrLengthChecker.out --> upperLayerOut;
        paddingInserter.out --> lowerLayerOut;
        lowerLayerIn --> { @display("m=s"); } --> addressChecker.in;
        addressChecker.out --> typeOrLengthChecker.in;
        upperLayerIn --> typeOrLengthInserter.in;
}

module EthernetLayer
{
    parameters:
        string interfaceTableModule;
        *.interfaceTableModule = default(interfaceTableModule);
        paddingInserter.minLength = default(60B);
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        c1: <default("PacketClassifier")> like IPacketClassifier {
            @display("p=200,300");
        }
        ctagInserter: <default("OmittedIeee8021qInserter")> like IIeee8021qInserter {
            vlanTagType = "c";
            @display("p=100,200");
        }
        stagInserter: <default("OmittedIeee8021qInserter")> like IIeee8021qInserter {
            vlanTagType = "s";
            @display("p=300,200");
        }
        typeOrLengthInserter: <default("EthernetTypeOrLengthInserter")> like IPacketFlow {
            @display("p=200,400");
        }
        addressInserter: <default("EthernetAddressInserter")> like IPacketFlow {
            @display("p=200,500");
        }
        paddingInserter: <default("PaddingInserter")> like IPacketFlow {
            @display("p=200,600");
        }
        typeOrLengthChecker: <default("EthernetTypeOrLengthChecker")> like IPacketFilter {
            @display("p=700,100");
        }
        ctagChecker: <default("OmittedIeee8021qChecker")> like IIeee8021qChecker {
            vlanTagType = "c";
            @display("p=800,300");
        }
        stagChecker: <default("OmittedIeee8021qChecker")> like IIeee8021qChecker {
            vlanTagType = "s";
            @display("p=600,300");
        }
        addressChecker: <default("EthernetAddressChecker")> like IPacketFilter {
            @display("p=700,500");
        }
        m1: PacketMultiplexer {
            @display("p=200,100");
        }
        c2: <default("PacketClassifier")> like IPacketClassifier {
            @display("p=700,200");
        }
        m2: PacketMultiplexer {
            @display("p=700,400");
        }
    connections:
        addressInserter.out --> paddingInserter.in;
        typeOrLengthInserter.out --> addressInserter.in;
        typeOrLengthChecker.out --> upperLayerOut;
        paddingInserter.out --> lowerLayerOut;
        lowerLayerIn --> { @display("m=s"); } --> addressChecker.in;
        c1.out++ --> ctagInserter.in;
        c1.out++ --> stagInserter.in;
        ctagInserter.out --> m1.in++;
        c1.out++ --> typeOrLengthInserter.in;
        stagInserter.out --> m1.in++;
        m1.out --> c1.in;
        upperLayerIn --> m1.in++;
        addressChecker.out --> m2.in++;
        m2.out --> c2.in;
        c2.out++ --> stagChecker.in;
        stagChecker.out --> m2.in++;
        ctagChecker.out --> m2.in++;
        c2.out++ --> typeOrLengthChecker.in;
        c2.out++ --> ctagChecker.in;
}

module SwitchEthernetLayer
{
    parameters:
        string interfaceTableModule;
        *.interfaceTableModule = default(interfaceTableModule);
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        ethernetRelay: EthernetRelay {
            @display("p=200,100");
        }
        ethernetLayer: EthernetLayer {
            @display("p=200,200");
        }
    connections:
        ethernetRelay.upperLayerOut --> upperLayerOut;
        upperLayerIn --> ethernetRelay.upperLayerIn;
        ethernetLayer.upperLayerOut --> ethernetRelay.lowerLayerIn;
        ethernetRelay.lowerLayerOut --> ethernetLayer.upperLayerIn;
        ethernetLayer.lowerLayerOut --> lowerLayerOut;
        lowerLayerIn --> ethernetLayer.lowerLayerIn;
}

module Ieee8022LlcLayer
{
    parameters:
        @display("i=block/layer");
    gates:
        input upperLayerIn;
        output upperLayerOut;
        input lowerLayerIn;
        output lowerLayerOut;
    submodules:
        classifier: <default("PacketClassifier")> like IPacketClassifier {
            @display("p=200,100");
        }
        snapInserter: <default("Ieee8022SnapInserter")> like IIeee8022SnapInserter if typename != "" {
            @display("p=100,200");
        }
        m1: PacketMultiplexer {
            @display("p=100,300");
        }
        llcInserter: <default("Ieee8022LlcInserter")> like IIeee8022LlcInserter if typename != "" {
            @display("p=100,400");
        }
        m2: PacketMultiplexer {
            @display("p=200,500");
        }
        protocolChecker: ProtocolChecker {
            @display("p=500,100");
        }
        llcChecker: <default("Ieee8022LlcChecker")> like IIeee8022LlcChecker {
            @display("p=400,400");
        }
        snapChecker: <default("Ieee8022SnapChecker")> like IIeee8022SnapChecker {
            @display("p=600,400");
        }
        dp: MessageDispatcher {
            @display("p=500,300;b=100,5,,,,1");
        }
    connections:
        upperLayerIn --> { @display("m=n"); } --> classifier.in;
        classifier.out++ --> snapInserter.in if exists(snapInserter);
        classifier.out++ --> m2.in++ if exists(llcInserter);
        classifier.out++ --> m1.in++;
        llcInserter.out --> m2.in++ if exists(llcInserter);
        snapInserter.out --> m1.in++ if exists(snapInserter);
        m2.out --> { @display("m=s"); } --> lowerLayerOut;

        lowerLayerIn --> { @display("m=s"); } --> dp.in++;
        dp.out++ --> llcChecker.in;
        protocolChecker.out --> { @display("m=n"); } --> upperLayerOut;
        m1.out --> llcInserter.in;
        llcChecker.out --> dp.in++;
        dp.out++ --> snapChecker.in;
        snapChecker.out --> dp.in++;
        dp.out++ --> protocolChecker.in;
}

module EthernetHost
{
    parameters:
        *.interfaceTableModule = default(absPath(".interfaceTable"));
        @networkNode;
        @display("i=device/pc2");
    gates:
        inout ethg @labels(EtherFrame-conn) @allowUnconnected;
    submodules:
        interfaceTable: InterfaceTable {
            @display("p=200,100;is=s");
        }
        app: <> like IApp {
            @display("p=500,100");
        }
        udp: Udp {
            @display("p=500,200");
        }
        ipv4: Ipv4NetworkLayer {
            @display("p=500,300");
        }
        ethernet: SimpleEthernetLayer {
            @display("p=500,400");
        }
        eth: HostEthernetInterface {
            @display("p=500,500;q=txQueue");
        }
    connections allowunconnected:
        app.socketOut --> udp.appIn;
        app.socketIn <-- udp.appOut;

        udp.ipOut --> ipv4.transportIn;
        udp.ipIn <-- ipv4.transportOut;

        ipv4.ifOut --> ethernet.upperLayerIn;
        ipv4.ifIn <-- ethernet.upperLayerOut;

        eth.upperLayerOut --> ethernet.lowerLayerIn;
        eth.upperLayerIn <-- ethernet.lowerLayerOut;

        ethg <--> { @display("m=s"); } <--> eth.phys;
}

module EthernetSwitch
{
    parameters:
        int numEthInterfaces = default(0);  // minimum number of ethernet interfaces
        *.macTableModule = default(absPath(".macTable"));
        *.interfaceTableModule = default(absPath(".interfaceTable"));
        @networkNode;
        @display("i=device/switch");
    gates:
        inout ethg[numEthInterfaces] @labels(EtherFrame-conn) @allowUnconnected;
    submodules:
        interfaceTable: InterfaceTable {
            @display("p=200,100;is=s");
        }
        macTable: <default("MacAddressTable")> like IMacAddressTable {
            @display("p=200,200;is=s");
        }
        relay1: MacRelayUnit {
            @display("p=500,100");
        }
        ethernet: SimpleEthernetLayer {
            @display("p=500,200");
        }
        li1: MessageDispatcher {
            @display("p=500,300;b=100,5,,,,1");
        }
        eth[sizeof(ethg)]: SwitchEthernetInterface {
            @display("p=500,400,row,150;q=txQueue");
        }
        li2: MessageDispatcher {
            @display("p=700,300;b=100,5,,,,1");
        }
        relay2: MacRelayUnit {
            @display("p=700,200");
        }
    connections allowunconnected:
        ethernet.lowerLayerOut --> li1.in++;
        li1.out++ --> ethernet.lowerLayerIn;

        for i=0..sizeof(ethg)-1 {
            eth[i].upperLayerOut --> li1.in++;
            eth[i].upperLayerIn <-- li1.out++;
        }

        relay2.ifOut --> li2.in++;
        li2.out++ --> relay2.ifIn;

        for i=0..sizeof(ethg)-1 {
            eth[i].cutthroughOut --> li2.in++;
            eth[i].cutthroughIn <-- li2.out++;
        }

        for i=0..sizeof(ethg)-1 {
            ethg[i] <--> { @display("m=s"); } <--> eth[i].phys;
        }

        relay1.ifOut --> ethernet.upperLayerIn;
        ethernet.upperLayerOut --> relay1.ifIn;
}
