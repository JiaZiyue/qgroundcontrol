#include "MotorComponent.h"

MotorComponent::MotorComponent(Vehicle* vehicle, AutoPilotPlugin* autopilot, QObject* parent)
    : VehicleComponent(vehicle, autopilot, AutoPilotPlugin::KnownMotorVehicleComponent, parent)
    , _name(tr("Motors"))
{

}
