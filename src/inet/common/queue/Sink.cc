//
// Copyright (C) 1992-2004 Andras Varga
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program; if not, see <http://www.gnu.org/licenses/>.
//

#include "inet/common/queue/Sink.h"
#include "inet/common/Simsignals.h"

namespace inet {

Define_Module(Sink);

void Sink::initialize()
{
    numPackets = 0;
    numBits = 0;
    throughput = 0;
    packetPerSec = 0;

    WATCH(numPackets);
    WATCH(numBits);
    WATCH(throughput);
    WATCH(packetPerSec);
}

void Sink::handleMessage(cMessage *msg)
{
    numPackets++;
    cPacket *packet = PK(msg);
    numBits += packet->getBitLength();
    emit(packetReceivedSignal, packet);
    throughput = numBits / simTime();
    packetPerSec = numPackets / simTime();

    delete msg;
}

void Sink::refreshDisplay() const
{
    char buf[80] = "";
    sprintf(buf, "rcvd: %d ", numPackets);
    getDisplayString().setTagArg("t", 0, buf);
}

void Sink::finish()
{
    recordScalar("throughput", throughput);
    recordScalar("packetPerSec", packetPerSec);
}

} // namespace inet

