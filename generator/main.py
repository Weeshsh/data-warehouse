import csv
import random
import os
import shutil
from datetime import datetime, timedelta, time
from collections import defaultdict
import bisect
import re

import numpy as np
from tqdm import tqdm
from faker import Faker


class IntervalChecker:
    def __init__(self):
        self.intervals = defaultdict(list)
        self.flat_intervals = defaultdict(list)
        self.dirty = set()

    def add_interval(self, lift_id, start_dt, end_dt):
        self.intervals[lift_id].append((start_dt, end_dt))
        self.dirty.add(lift_id)

    def _finalize(self, lift_id):
        if lift_id in self.dirty:
            self.intervals[lift_id].sort(key=lambda x: x[0])
            flat = []
            for start, end in self.intervals[lift_id]:
                flat.extend([start, end])
            self.flat_intervals[lift_id] = flat
            self.dirty.discard(lift_id)

    def is_blocked(self, lift_id, check_time):
        self._finalize(lift_id)
        flat = self.flat_intervals[lift_id]
        if not flat:
            return False

        idx = bisect.bisect_right(flat, check_time)

        return idx % 2 != 0

def parse_date_arg(val, reference_date=None):
    """Converts '-365d' or '2024-01-01' to datetime object."""
    if isinstance(val, datetime):
        return val
    if reference_date is None:
        reference_date = datetime.now()

    match = re.match(r"^(-?)(\d+)([dhm])$", val)
    if match:
        sign, amount, unit = match.groups()
        amount = int(amount)
        if sign == "-":
            amount = -amount

        delta_args = {'d': 'days', 'h': 'hours', 'm': 'minutes'}
        return reference_date + timedelta(**{delta_args[unit]: amount})

    try:
        return datetime.strptime(val, "%Y-%m-%d")
    except ValueError:
        pass

    return reference_date

def random_time_in_day(date_obj, start_h=8, end_h=20):
    start_sec = start_h * 3600
    end_sec = end_h * 3600
    r_sec = np.random.randint(start_sec, end_sec)
    return datetime.combine(date_obj, time(0, 0)) + timedelta(seconds=int(r_sec))

def write_csv(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(rows)


def main(
    s=10,
    data_poczatek_str="-365d",
    data_koniec_str="-1d",
    N_AWARIE=800,
    N_PRZEGLADY=1000,
    N_PRZYSTOJE=10000,
    OUTPUT_DIR="snapshot_1",
    append_mode=False
):
    print(f"--- Starting generation for {OUTPUT_DIR} ---")

    random.seed(s)
    np.random.seed(s)
    Faker.seed(s)
    fake = Faker("pl_PL")

    start_dt = parse_date_arg(data_poczatek_str)
    end_dt = parse_date_arg(data_koniec_str)

    os.makedirs(OUTPUT_DIR, exist_ok=True)

    N_SKIERS = 10000
    N_RIDES_PER_DAY = 20
    N_SKIERS_PER_DAY = 250
    N_WYCIAGI = 20 if OUTPUT_DIR == "snapshot_1" else 21
    N_TYPY_AWARII = 5
    skiers_ids = np.random.randint(10000, 90000, size=N_SKIERS)

    wyciagi = []
    for i in range(1, N_WYCIAGI + 1):
        wyciagi.append([i, f"Trasa_{i}", random.randint(1, 5), random.randint(40, 100) * 15])

    write_csv(os.path.join(OUTPUT_DIR, "wyciagi.csv"), ["ID", "Nazwa", "Trudnosc", "Czas_zjazdu"], wyciagi)

    awarie_types = ["Awaria silnika", "Awaria liny", "Awaria czujnikow", "Awaria systemowa", "Awaria wspornikow"]
    awarie_opisy = [
        "Problemy z praca jednostki napedowej.", "Uszkodzenie, przetarcie lub zerwanie liny.",
        "Nieprawidlowe dzialanie lub brak odczytow z czujnikow.", "Blad w dzialaniu oprogramowania.",
        "Uszkodzenie lub poluzowanie elementow."
    ]
    typy_awarii = [[i+1, awarie_types[i], awarie_opisy[i]] for i in range(5)]
    write_csv(os.path.join(OUTPUT_DIR, "typy_awarii.csv"), ["ID", "Nazwa", "Opis"], typy_awarii)


    awarie = []
    existing_intervals = defaultdict(list) # For generation phase overlap check

    def check_overlap(lid, start, end):
        for s, e in existing_intervals[lid]:
            if max(start, s) < min(end, e): # Overlap condition
                return True
        return False

    print("Generating Awarie...")
    with tqdm(total=N_AWARIE) as pbar:
        while len(awarie) < N_AWARIE:
            lid = random.randint(1, N_WYCIAGI)
            start = fake.date_time_between(start_date=start_dt, end_date=end_dt)
            duration_days = random.randint(0, 7)
            end = start + timedelta(days=duration_days, hours=random.randint(1, 23))

            if check_overlap(lid, start, end):
                continue

            existing_intervals[lid].append((start, end))

            cost = round(random.uniform(200, 2000) * (duration_days + 1), 2)
            awarie.append([len(awarie)+1, start, end, random.randint(1, 5), cost, lid, random.randint(1, 5)])

            checker.add_interval(lid, start, end)
            pbar.update(1)

    awarie.sort(key=lambda x: x[1])
    for i, r in enumerate(awarie): r[0] = i + 1

    write_csv(os.path.join(OUTPUT_DIR, "awarie.csv"),
              ["ID", "Data_zdarzenia", "Data_zakonczenia", "Poziom_uszkodzen", "Koszt", "FK_Wyciag", "FK_Typ"],
              awarie)

    print("Generating Przystoje...")
    przystoje = []

    for _ in tqdm(range(N_PRZYSTOJE)):
        lid = random.randint(1, N_WYCIAGI)
        start = random_time_in_day(fake.date_between(start_dt.date(), end_dt.date()))
        duration_min = random.randint(1, 10)
        end = start + timedelta(minutes=duration_min)

        if checker.is_blocked(lid, start):
            continue

        przystoje.append([0, start, duration_min, lid])
        checker.add_interval(lid, start, end)

    przystoje.sort(key=lambda x: x[1])
    for i, r in enumerate(przystoje): r[0] = i + 1

    write_csv(os.path.join(OUTPUT_DIR, "przystoje.csv"),
              ["ID", "Data_zdarzenia", "Dlugosc_przystoju", "FK_Wyciag"], przystoje)

    print("Generating Przeglady...")
    przeglady = []
    count = 0
    pbar = tqdm(total=N_PRZEGLADY)
    while count < N_PRZEGLADY:
        lid = random.randint(1, N_WYCIAGI)
        start = random_time_in_day(fake.date_between(start_dt.date(), end_dt.date()))
        end = start + timedelta(hours=2)

        if checker.is_blocked(lid, start):
            continue

        przeglady.append([0, round(random.uniform(100, 2000), 2), start, lid])
        checker.add_interval(lid, start, end)
        count += 1
        pbar.update(1)
    pbar.close()

    przeglady.sort(key=lambda x: x[2])
    for i, r in enumerate(przeglady): r[0] = i + 1

    write_csv(os.path.join(OUTPUT_DIR, "przeglady.csv"),
              ["ID", "Koszt", "Data_wykonania", "FK_Wyciag"], przeglady)

    print("Generating Logs (Optimized)...")

    logi_file = os.path.join(OUTPUT_DIR, "logi_bramek.csv")

    total_days = (end_dt - start_dt).days + 1

    lift_durations = {row[0]: row[3] for row in wyciagi}

    with open(logi_file, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["ID", "Timestamp", "Numer_Wyciagu", "ID_Karty"])

        log_id_counter = 1
        if append_mode:
            pass

        current_day = start_dt

        with tqdm(total=total_days, desc="Simulating Days") as pbar_days:
            while current_day <= end_dt:

                todays_skiers_indices = np.random.choice(len(skiers_ids), N_SKIERS_PER_DAY, replace=False)
                todays_skiers = skiers_ids[todays_skiers_indices]

                start_seconds = np.random.randint(8*3600, 12*3600, size=N_SKIERS_PER_DAY)
                base_time = datetime.combine(current_day.date(), time(0,0))

                day_logs = []

                for i, skier_id in enumerate(todays_skiers):
                    curr_time = base_time + timedelta(seconds=int(start_seconds[i]))
                    current_lift = random.randint(1, N_WYCIAGI)

                    rides_done = 0
                    attempts = 0

                    while rides_done < N_RIDES_PER_DAY and attempts < N_RIDES_PER_DAY * 2:
                        attempts += 1

                        if checker.is_blocked(current_lift, curr_time):
                            # Wait a bit or change lift
                            curr_time += timedelta(minutes=15)
                            current_lift = random.randint(1, N_WYCIAGI)
                            continue

                        day_logs.append([log_id_counter, curr_time, current_lift, skier_id])
                        log_id_counter += 1
                        rides_done += 1

                        ride_dur = lift_durations.get(current_lift, 300)
                        break_time = random.randint(300, 1200)
                        curr_time += timedelta(seconds=ride_dur + break_time)

                        if random.random() > 0.7:
                            current_lift = random.randint(1, N_WYCIAGI)

                        if curr_time.hour >= 21:
                            break

                if day_logs:
                    day_logs.sort(key=lambda x: x[1])
                    writer.writerows(day_logs)

                current_day += timedelta(days=1)
                pbar_days.update(1)

    print(f"Done. Generated {log_id_counter-1} logs in {OUTPUT_DIR}/logi_bramek.csv")


def snap2():
    """
    Generates Snapshot 2 efficiently.
    Instead of manual text appending, it generates new data into a temp folder,
    then merges strictly via file operations.
    """
    main(s=11,
         data_poczatek_str="-220d",
         data_koniec_str="-200d",
         N_AWARIE=30,
         N_PRZEGLADY=20,
         N_PRZYSTOJE=50,
         OUTPUT_DIR="snapshot_2_temp")

    print("Merging Snapshot 1 and Snapshot 2...")

    os.makedirs("snapshot_2", exist_ok=True)

    for f in ["wyciagi.csv", "typy_awarii.csv"]:
        shutil.copy(os.path.join("snapshot_2_temp", f), os.path.join("snapshot_2", f))

    files_to_merge = ["awarie.csv", "przystoje.csv", "przeglady.csv", "logi_bramek.csv"]

    for filename in files_to_merge:
        p1 = os.path.join("snapshot_1", filename)
        p2 = os.path.join("snapshot_2_temp", filename)
        out = os.path.join("snapshot_2", filename)

        with open(out, 'w', newline='', encoding='utf-8') as f_out:
            writer = csv.writer(f_out)

            max_id = 0
            headers = []

            if os.path.exists(p1):
                with open(p1, 'r', encoding='utf-8') as f1:
                    reader = csv.reader(f1)
                    try:
                        headers = next(reader)
                        writer.writerow(headers)
                        for row in reader:
                            writer.writerow(row)
                            try:
                                max_id = max(max_id, int(row[0]))
                            except: pass
                    except StopIteration:
                        pass

            if os.path.exists(p2):
                with open(p2, 'r', encoding='utf-8') as f2:
                    reader = csv.reader(f2)
                    try:
                        next(reader)
                        for row in reader:
                            row[0] = int(row[0]) + max_id
                            writer.writerow(row)
                    except StopIteration:
                        pass

    shutil.rmtree("snapshot_2_temp")
    print("Snapshot 2 created successfully.")

if __name__ == "__main__":
    main()

    # snap2()
