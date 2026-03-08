import { RideRequestForm } from '../../components/rides/ride-request-form';

export default function RidesPage() {
  return (
    <section className="space-y-4">
      <h2 className="text-3xl font-semibold">Request a Ride</h2>
      <RideRequestForm />
    </section>
  );
}